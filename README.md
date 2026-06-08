# coreutils

[GNU coreutils](https://www.gnu.org/software/coreutils/) — `ls`, `cat`, `cp`, `mv`, `rm` and ~100 other core file, text and shell programs, packaged as a single self-contained binary built natively for Linux, macOS, and Windows.

[![CI](https://github.com/unpins/coreutils/actions/workflows/coreutils.yml/badge.svg)](https://github.com/unpins/coreutils/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install coreutils`.

## Usage

coreutils is one binary holding ~100 programs. It picks which one to run from the name it's invoked as, so the natural way to use it is to install the programs onto your PATH:

```bash
unpin install coreutils
ls -la /
sha256sum file
```

To run a program without installing, name it with `--coreutils-prog=`:

```bash
unpin coreutils --coreutils-prog=ls -la /
```

`unpin coreutils --help` lists every built-in program.

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

## Build notes

- **Windows** is built with [Cosmopolitan](https://justine.lol/cosmopolitan/); Linux and macOS use static builds. All three ship the same multicall binary from the same source.
- **Disabled:** SELinux contexts (`-Z`, `runcon`), libgmp (mini-gmp fallback for `factor`/`expr`), and OpenSSL checksum acceleration. ACL and xattr preservation are on for Linux/macOS, off on Windows. No embedded man pages — coreutils generates only per-program pages, with no combined page for the multicall to embed.
- **Tests:** the functional suite passes on native static-musl Linux (434 / 0). The `gnulib-tests` portability units (threading/locale/TLS) are skipped — they assume glibc semantics, not musl.
