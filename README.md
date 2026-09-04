# coreutils

[GNU coreutils](https://www.gnu.org/software/coreutils/) — `ls`, `cat`, `cp`, `mv`, `rm` and ~100 other core file, text and shell programs. A single self-contained binary, built natively for Linux, macOS, and Windows.

[![CI](https://github.com/unpins/coreutils/actions/workflows/coreutils.yml/badge.svg)](https://github.com/unpins/coreutils/actions)
![Linux](https://img.shields.io/badge/Linux-✓-success?logo=linux&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-✓-success?logo=apple&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-✓-success?logo=windows&logoColor=white)

Part of the [unpins](https://unpins.org) catalog; install it with [`unpin`](https://github.com/unpins/unpin): `unpin install coreutils`.

## Usage

Run a program with [unpin](https://github.com/unpins/unpin):

```bash
unpin coreutils --unpin-program=ls -la /
unpin coreutils --unpin-program=sha256sum file
```

To install the programs onto your PATH:

```bash
unpin install coreutils
ls -la /
sha256sum file
```

`unpin install coreutils` creates all ~105 programs as commands — `ls`, `cat`, `cp`, `mv`, `rm`, `sort`, `sha256sum`, … (full list: `unpin info coreutils`).

## Man pages

One page per program is embedded — read any with `unpin man coreutils <program>`, e.g. `unpin man coreutils ls`.

## Build locally

```bash
nix build github:unpins/coreutils
./result/bin/coreutils --unpin-program=ls /
```

Or run directly:

```bash
nix run github:unpins/coreutils -- --unpin-program=ls /
```

The first invocation will offer to add the [unpins.cachix.org](https://unpins.cachix.org) substituter so most pulls come pre-built.

## Manual download

The [Releases](https://github.com/unpins/coreutils/releases) page has standalone binaries for manual download.

## Build notes

- **Windows** uses [Cosmopolitan](https://justine.lol/cosmopolitan/), not mingw: the vendored gnulib assumes `fork`/`waitpid` (`lib/savewd.c`), which mingw does not provide.
- **Disabled:** SELinux contexts (`-Z`, `chcon`, `runcon`), libgmp (mini-gmp fallback for `factor`/`expr`), and OpenSSL checksum acceleration. ACL and xattr preservation are on for Linux/macOS, off on Windows.
- **Tests:** the functional suite (coreutils' own `tests/`) runs on native builds and passes under static-musl (0 failures); it auto-skips on cross targets the build host can't execute. The `gnulib-tests` portability units (threading/locale/TLS) are excluded — they assume glibc semantics, not musl.
