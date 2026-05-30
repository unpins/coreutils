# coreutils

Standalone build of [GNU coreutils](https://www.gnu.org/software/coreutils/), shipped as a single multicall binary (busybox-style) via `--enable-single-binary=symlinks`.

[![CI](https://github.com/unpins/coreutils/actions/workflows/coreutils.yml/badge.svg)](https://github.com/unpins/coreutils/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) project — native single-binary builds with no third-party runtime dependencies.

Linux/macOS use `pkgsStatic`. Windows is built via [Cosmopolitan](https://justine.lol/cosmopolitan/) (cosmocc cross-toolchain inside Nix) because mingw cross of GNU coreutils fails in gnulib (`waitpid`/fork POSIX assumptions in `lib/savewd.c` and friends). All three platforms ship the same multicall binary built from the same upstream source.

## Usage

The package ships one executable, `coreutils` (`coreutils.exe` on Windows). `unpin install` materializes per-applet shims (`ls`, `cat`, `cp`, …) next to the multicall using argv[0] dispatch. To run a command directly without installing, use the `--coreutils-prog=` flag:

```bash
coreutils --coreutils-prog=ls -la
coreutils --coreutils-prog=sha256sum file
```

Or create symlinks named after the commands you want to use as bare names:

```bash
ln -s "$(command -v coreutils)" ~/bin/ls
ls -la
```

Built-in programs include: `ls`, `cat`, `cp`, `mv`, `rm`, `mkdir`, `rmdir`, `ln`, `chmod`, `chown`, `dd`, `df`, `du`, `head`, `tail`, `sort`, `uniq`, `wc`, `cut`, `paste`, `tr`, `sed`-free text tools (`expand`, `fold`, `fmt`, …), checksums (`md5sum`/`sha*sum`/`cksum`/`b2sum`), `base32`/`base64`, `date`, `env`, `printf`, `stat`, `realpath`, `readlink`, `seq`, `sleep`, `timeout`, `nproc`, `nohup`, `tee`, `yes`, and more (~100 total — `coreutils --help` for the full list).

## Disabled options

- ACL preservation — Windows only (native on Linux + macOS)
- xattr support — Windows only (native on Linux + macOS)
- SELinux (`-Z`, `runcon` contexts)
- libgmp (large-int `factor` / `expr` / `basenc` use mini-gmp fallback)
- OpenSSL acceleration for `md5sum` / `sha*sum`
- Locale catalogs and man pages (no embedded man: coreutils generates only per-applet pages, with no combined `coreutils.1` for the multicall to embed)

The functional test suite (`tests/`) *does* run on native Linux — 434 pass / 0 fail under static-musl. Only the `gnulib-tests/` portability units (threading/locale/TLS) are skipped: they assume glibc semantics and fail under musl, and exercise gnulib infrastructure rather than coreutils itself.

## Installation

Install with [unpin](https://github.com/unpins/unpin):

```bash
unpin coreutils
```

Or run without installing:

```bash
unpin run coreutils
```

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
