# Changelog

## [Unreleased]

### Fixed

- The `stdbuf` man page was embedded, and `--unpin-program=stdbuf` was
  accepted, although `stdbuf` cannot work in a self-contained binary: it works
  by loading a separate library into the program it runs. Both are gone.

## [9.11-2] - 2026-09-26

### Fixed

- `--unpin-program=install` now runs `install`. It reported "unknown program"
  because upstream keys that program internally as `ginstall` and only maps the
  name when the binary is invoked as `install` — so the shim created by
  `unpin install coreutils` worked, but selecting it by name did not.
