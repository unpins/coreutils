{
  description = "Standalone build of coreutils";

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
      # Probe whether cosmo Windows argv reaches main() intact — links
      # rejects every single-dash and double-dash option on cosmo Win.
      # If coreutils --version works here, the bug is specific to links;
      # if it also fails, it's a cosmocc runtime / apelink issue.
      smoke = [ "--version" ];
      smokePattern = "GNU coreutils";
      build = pkgs:
        unpins-lib.lib.withAliases pkgs
          {
            primary = "coreutils";
            aliasesFromSymlinksIn = "bin";
          }
          pkgs.pkgsStatic.coreutils;
    };
}
