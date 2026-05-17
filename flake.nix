{
  description = "Standalone build of coreutils";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # Linux/macOS: native pkgsStatic via mkStandaloneFlake. Windows: routed
  # through Cosmopolitan (`windowsCosmo = true`) because mingw cross of GNU
  # coreutils fails in gnulib (waitpid/fork POSIX assumptions in lib/savewd.c
  # and friends — same family of breakage as bash/git). Per-target cosmo
  # fixes live in `unpins/nix-lib/cosmo/coreutils.{nix,patch}`.
  #
  # Ships the multicall `coreutils` binary built with `--enable-single-binary=symlinks`
  # on every platform (`coreutils.exe` on Windows). Per-applet symlinks are
  # stripped by `lib.withAliases` after embedding the applet names as an
  # UNPIN_META block so `unpin install` can materialize argv[0]-dispatch shims.
  outputs = { self, unpins-lib }:
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "coreutils";
      windowsCosmo = true;
      # Probe whether cosmo Windows argv reaches main() intact — links
      # rejects every single-dash and double-dash option on cosmo Win.
      # If coreutils --version works here, the bug is specific to links;
      # if it also fails, it's a cosmocc runtime / apelink issue.
      smoke = [ "--version" ];
      smokePattern = "GNU coreutils";
    };
}
