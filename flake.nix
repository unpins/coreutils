{
  description = "coreutils as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # Linux/macOS: native pkgsStatic via mkStandaloneFlake. Windows: routed
  # through Cosmopolitan (`windowsBuild = import ./cosmo.nix …`) because
  # mingw cross of GNU coreutils fails in gnulib (waitpid/fork POSIX
  # assumptions in lib/savewd.c and friends — same family of breakage as
  # bash/git). Per-binary cosmo recipe + patch sit in `./cosmo.nix` +
  # `./coreutils-cosmo.patch`.
  #
  # Upstream builds the multicall with `--enable-single-binary=symlinks`:
  # one real `coreutils` in $out/bin plus a symlink per applet (ls, cat,
  # cp, …). We ship only the multicall; the UNPIN_META block embedded by
  # `lib.withAliases` tells unpin's installer to create the alias links
  # itself at install time (argv[0]-dispatch). Helper collects the applet
  # names from the upstream symlinks before wiping them — single source
  # of truth, no hand-maintained list.
  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "coreutils";
      windowsBuild = import ./cosmo.nix { inherit unpins-lib; };
      # coreutils dispatches its applet from argv[0]. The Windows smoke
      # decompresses the release artifact to `smoke.exe` and runs it, so
      # argv[0] is "smoke" — a bare `smoke.exe --version` errors with
      # `unknown program 'smoke'`. (Linux keeps the binary named `coreutils`,
      # so it didn't surface there.) `--unpin-program=env` picks the applet
      # explicitly, independent of argv[0] (it is the unified catalog selector,
      # a synonym of coreutils' own `--coreutils-prog=` added in
      # ./coreutils-unpin-program.patch); `env --version` still prints the
      # "GNU coreutils" version banner. Works whether invoked as coreutils or
      # smoke.exe (both verified locally).
      smoke = [ "--unpin-program=env" "--version" ];
      smokePattern = "GNU coreutils";
      build = pkgs:
        let sp = pkgs.pkgsStatic; in
        unpins-lib.lib.withAliases pkgs
          {
            primary = "coreutils";
            aliasesFromSymlinksIn = "bin";
          }
          # Feature matrix:
          #   acl / attr: on for Linux (libacl / libattr from pkgsStatic);
          #     darwin keeps the override at false because the nixpkgs `acl`
          #     and `attr` packages are Linux-only — but coreutils's configure
          #     auto-detects native ACL / xattr from libSystem (`<sys/acl.h>`,
          #     `<sys/xattr.h>`) without needing them. Off on cosmo (no API).
          #   selinuxSupport: Linux-kernel-only and would drag libselinux.
          #   gmpSupport:     arb-precision factor/expr/basenc fall back to
          #                   gnulib's mini-gmp; also dodges a flaky
          #                   `gmp-with-cxx-static tests/mpq` under musl
          #                   pkgsStatic.
          #   withOpenssl:    md5sum / sha*sum keep gnulib implementations —
          #                   fewer transitive deps, smaller closure.
          ((sp.coreutils.override {
            # minimal=false flips pname to coreutils-full and, crucially, keeps
            # `$out/share/man` (the default `minimal=true` runs `rm -r $out/share`
            # in postInstall). The man pages are still generated — the static
            # build GENs them and the isCross postInstall installs man/*.1 — so
            # this is what lets `unpin man coreutils <applet>` work via the
            # embedded `unpin/man/*` ZIP. withOpenssl stays false (overridden
            # below) so we don't pull openssl that minimal=false would otherwise
            # default-on. Extra build-time share/locale is dropped from the final
            # bin-only output by strippedOrJoined.
            minimal = false;
            aclSupport = pkgs.stdenv.hostPlatform.isLinux;
            attrSupport = pkgs.stdenv.hostPlatform.isLinux;
            selinuxSupport = false;
            gmpSupport = false;
            withOpenssl = false;
            singleBinary = "symlinks";
          }).overrideAttrs (old: {
            # Teach the multicall binary unpins' uniform `--unpin-program=NAME`
            # selector (a synonym of coreutils' own `--coreutils-prog=`), so
            # every catalog multicall is driven the same way. See
            # docs/multicall.md. The cosmo/Windows build applies the same patch
            # in ./cosmo.nix.
            patches = (old.patches or [ ]) ++ [ ./coreutils-unpin-program.patch ];

            # Run coreutils' own functional suite (tests/) on native Linux:
            # 434 pass / 0 fail under pkgsStatic-musl (verified locally). The
            # top-level `make check` ALSO recurses into gnulib-tests/, whose
            # threading/locale/TLS units (test-lock, test-tls, test-rwlock1,
            # test-*-mt, …) assume glibc semantics and fail under musl — those
            # exercise gnulib infrastructure, not coreutils — so the check is
            # restricted to tests/. Cross builds skip via canExecute;
            # darwin-native is left off (not locally verifiable — revisit via
            # the Mac builder). See docs/releasing.md "Native test suite".
            doCheck = sp.stdenv.hostPlatform.isLinux
              && sp.stdenv.buildPlatform.canExecute sp.stdenv.hostPlatform;
            checkTarget = "check";
            checkPhase = ''
              runHook preCheck
              make -C tests check VERBOSE=yes
              runHook postCheck
            '';
          }));
    };
}
