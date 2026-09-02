# coreutils via cosmoStaticCross for Windows-x86_64.
#
# Tracks nixpkgs's pinned coreutils version (currently 9.8) so all three
# unpins targets — Linux / macOS / Windows — ship the same source. The
# 9.4 pin documented in earlier revisions was needed because that
# gnulib's `getlocalename_l-unsafe.c` hard-errored on cosmo; the 9.8
# vendored gnulib no longer trips that, so the pin is gone.
#
# What the patch (`coreutils-cosmo.patch`) fixes:
#
# - Enum initializers backed by non-constant macros — cosmocc expands
#   POSIX_FADV_* / O_* / PIPE_BUF to non-constant expressions, so any
#   `enum { X = MACRO }` site fails. Affected files: lib/fadvise.h,
#   src/dd.c, src/factor.c. Rewritten as #defines (with `typedef int
#   fadvice_t` to keep callers compiling); static_asserts in dd.c
#   bracketed in `#if 0`; FACTOR_PIPE_BUF hard-coded to 4096 because
#   `static char lbuf_buf[2*FACTOR_PIPE_BUF]` at file scope requires
#   a compile-time constant.
# - lib/canonicalize.c — drop a `FALLTHROUGH;` after a `break`; the
#   cosmocc compiler diagnoses unreachable fall-through.
# - lib/getlocalename_l-unsafe.c — gnulib has a `#error "Please port
#   to your platform!"` for unknown systems. Add a `__COSMOCC__` branch
#   that returns "C" (cosmo's locale story is minimal anyway).
#
# Configure overrides:
#   - ac_cv_header_error_h=no:    cosmocc has no <error.h>; without
#                                 this, autoconf may accept a stray
#                                 match, gnulib then skips its
#                                 replacement, and lib/mkdir-p.c can't
#                                 find error()
#   - ac_cv_func_sethostname=yes: cosmocc exposes sethostname but
#                                 autoconf's link probe doesn't see it
#   - S_I[RWX]UGO defines:        GNU file-mode shortcuts cosmocc's
#                                 <sys/stat.h> doesn't ship
#
# Why we disable so much via .override:
#   - aclSupport / attrSupport: cosmo has no <sys/acl.h> / <sys/xattr.h>
#   - selinuxSupport:           libselinux is Linux-only
#   - gmpSupport:               we'd have to cosmo-build gmp; skip it and
#                               lose only `factor` / `numfmt` arb-precision
#   - withOpenssl:              md5/sha* fall back to gnulib's own
#
# minimal = false is the one thing we turn ON, for the same reason the native
# build does: minimal (the nixpkgs default) ends its postInstall with
# `rm -r "$out/share"`, which takes the man pages with it, and unpinEmbedWrap
# then finds no `share/man` to embed — `unpin man coreutils <applet>` dead on
# Windows while Linux had all 106. help2man cannot run a cross-built binary, so
# nixpkgs itself grafts `buildPackages.coreutils-full`'s pages in on the cross
# path; we only have to ask for them. withOpenssl stays pinned false below,
# since it defaults to `!minimal`.
{ unpins-lib }:
pkgs:
let
  cosmoPkgs = unpins-lib.lib.cosmoStaticCross pkgs;

  patched = (cosmoPkgs.coreutils.override {
    aclSupport = false;
    attrSupport = false;
    selinuxSupport = false;
    gmpSupport = false;
    withOpenssl = false;
    minimal = false;
    singleBinary = "symlinks";
  }).overrideAttrs (oa: {
    patches = (oa.patches or [ ]) ++ [
      ./coreutils-cosmo.patch
      # Uniform `--unpin-program=NAME` multicall selector (synonym of
      # `--coreutils-prog=`); also applied on the native build in flake.nix.
      ./coreutils-unpin-program.patch
    ];

    # cosmocc's libc claims several short identifiers that clash with
    # coreutils helpers — different signatures, so the compiler can't
    # accept both declarations. We rename the coreutils side. The regex
    # anchors on `(` so `#include "fadvise.h"` etc. survive untouched.
    # Done as sed (not patch) because it's a global symbol rename across
    # many files; the version-pinned source patch stays focused on the
    # enum→#define transforms.
    #
    #   fadvise        cosmocc: int(int, u64, u64, int) in <libc/calls/calls.h>
    #                  coreutils: void(FILE*, fadvice_t) in lib/fadvise.h
    #   touch          cosmocc: in <libc/calls/calls.h>
    #                  coreutils: static bool(const char*) in src/touch.c
    #   timespec_cmp   cosmocc: in <libc/calls/struct/timespec.h>
    #                  coreutils: in lib/timespec.h + 4 callers
    #   issymlink      cosmocc: `#define issymlink __issymlink` macro
    #                  coreutils: gnulib header-inline in lib/issymlink.{h,c}
    #                  → without rename, our inline emits as `__issymlink`
    #                    in every TU and the linker rejects multi-def.
    postPatch = (oa.postPatch or "") + ''
      rename_call_sites() {
          local sym="$1" newsym="$2"; shift 2
          local files=$(grep -lE "\b$sym[[:space:]]*\(" "$@" 2>/dev/null)
          [ -n "$files" ] && sed -i -E "s/\b$sym([[:space:]]*\()/$newsym\1/g" $files
      }
      rename_call_sites fadvise      cu_fadvise      lib/fadvise.h lib/fadvise.c src/*.c
      rename_call_sites touch        cu_touch        src/touch.c
      rename_call_sites timespec_cmp cu_timespec_cmp lib/timespec.h lib/*.c src/*.c
      rename_call_sites issymlink    cu_issymlink    lib/issymlink.h lib/*.c src/*.c
    '';

    configureFlags = (oa.configureFlags or [ ]) ++ [
      "ac_cv_header_error_h=no"
      "ac_cv_func_sethostname=yes"
      "--disable-nls"
      "--disable-xattr"
      "--disable-rpath"
      "--disable-acl"
      "--disable-assert"
    ];

    env = (oa.env or { }) // {
      NIX_CFLAGS_COMPILE = builtins.concatStringsSep " " [
        (oa.env.NIX_CFLAGS_COMPILE or "")
        "-Wno-implicit-function-declaration"
        "-DS_IXUGO=0111"
        "-DS_IRUGO=0444"
        "-DS_IWUGO=0222"
        "-DS_IRWXUGO=0777"
      ];
    };
  });

  # ELF → PE32+ rename to `coreutils.exe` happens automatically via the
  # cosmo cross stdenv's apelink setup hook (preFixupHook). The applet list
  # the .exe announces comes from `multicallCosmo.aliases`, which is the same
  # `applets` the fold dispatches — not harvested from these symlinks.
in
patched
