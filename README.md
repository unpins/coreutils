# coreutils

Standalone build of [GNU coreutils](https://www.gnu.org/software/coreutils/), shipped as a single multicall binary (busybox-style) via `--enable-single-binary=symlinks`.

[![CI](https://github.com/unpins/coreutils/actions/workflows/coreutils.yml/badge.svg)](https://github.com/unpins/coreutils/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) project — native single-binary builds with no third-party runtime dependencies.

Linux/macOS use `pkgsStatic`. Windows is built via [Cosmopolitan](https://justine.lol/cosmopolitan/) (cosmocc cross-toolchain inside Nix) because mingw cross of GNU coreutils fails in gnulib (`waitpid`/fork POSIX assumptions in `lib/savewd.c` and friends). All three platforms ship the same multicall binary built from the same upstream source.

## Usage

coreutils is one binary with ~100 programs (`ls`, `cat`, `cp`, `mv`, `rm`, …). GNU's single binary picks the program from `argv[0]` (the name it's invoked as) or the `--coreutils-prog=` flag — not from the first argument — so run a program with [unpin](https://github.com/unpins/unpin) via that flag:

```bash
unpin coreutils --coreutils-prog=ls -la /
unpin coreutils --coreutils-prog=sha256sum file
```

Run it with `--help` to list every built-in program:

```bash
unpin coreutils --help
```

To install onto your PATH (each program becomes its own command — `ls`, `cat`, `cp`, …, dispatched by `argv[0]`):

```bash
unpin install coreutils
ls -la /
```

Built-in programs (~100 total): `ls`, `cat`, `cp`, `mv`, `rm`, `mkdir`, `rmdir`, `ln`, `chmod`, `chown`, `dd`, `df`, `du`, `head`, `tail`, `sort`, `uniq`, `wc`, `cut`, `paste`, `tr`, text tools (`expand`, `fold`, `fmt`, …), checksums (`md5sum`/`sha*sum`/`cksum`/`b2sum`), `base32`/`base64`, `date`, `env`, `printf`, `stat`, `realpath`, `readlink`, `seq`, `sleep`, `timeout`, `nproc`, `nohup`, `tee`, `yes`, and more.

## Disabled options

- ACL preservation — Windows only (native on Linux + macOS)
- xattr support — Windows only (native on Linux + macOS)
- SELinux (`-Z`, `runcon` contexts)
- libgmp (large-int `factor` / `expr` / `basenc` use mini-gmp fallback)
- OpenSSL acceleration for `md5sum` / `sha*sum`
- Locale catalogs and man pages (no embedded man: coreutils generates only per-applet pages, with no combined `coreutils.1` for the multicall to embed)

The functional test suite (`tests/`) *does* run on native Linux — 434 pass / 0 fail under static-musl. Only the `gnulib-tests/` portability units (threading/locale/TLS) are skipped: they assume glibc semantics and fail under musl, and exercise gnulib infrastructure rather than coreutils itself.

## Build locally

```bash
nix build github:unpins/coreutils
./result/bin/coreutils --coreutils-prog=ls /
```

Or run directly:

```bash
nix run github:unpins/coreutils -- --coreutils-prog=ls /
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/coreutils/releases) page has standalone binaries for manual download.
