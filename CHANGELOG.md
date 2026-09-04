# Changelog

## [Unreleased]

### Fixed

- `--unpin-program=install` now runs `install`. It reported "unknown program"
  because upstream keys that program internally as `ginstall` and only maps the
  name when the binary is invoked as `install` — so the shim created by
  `unpin install coreutils` worked, but selecting it by name did not.
