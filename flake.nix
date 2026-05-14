{
  description = "Standalone build of coreutils";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # Native-only by design. mingw cross of GNU coreutils fails in gnulib
  # (waitpid/fork POSIX assumptions in lib/savewd.c and friends — same family
  # of breakage as bash/git). uutils-coreutils (Rust) would cross cleanly but
  # mixing flavors per-platform would be surprising. See
  # feedback_unpins_coreutils_windows_blocked.md in memory.
  #
  # Ships the multicall `coreutils` binary built with --enable-single-binary=symlinks
  # (nixpkgs default). Per-command symlinks are stripped in nix-lib's fixes registry;
  # invoke as `coreutils --coreutils-prog=ls /tmp` or via user-created symlinks.
  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "coreutils";
    };
}
