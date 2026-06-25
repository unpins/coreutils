{
  description = "coreutils as a single self-contained binary";

  nixConfig = {
    extra-substituters = [ "https://unpins.cachix.org" ];
    extra-trusted-public-keys = [ "unpins.cachix.org-1:DDaShjbZ8VvcqxeTcAU3kV9vxZQBlyb7V/uLBHfTynI=" ];
  };

  inputs.unpins-lib.url = "github:unpins/nix-lib";

  # Windows goes through Cosmopolitan, not mingw: mingw cross fails in gnulib
  # (waitpid/fork POSIX assumptions in lib/savewd.c — same family as bash/git).
  outputs = { self, unpins-lib }:
    let
      # Applet names harvested from upstream's single-binary symlinks, single
      # source of truth for both multicall modules below. Cosmo lacks gethostid,
      # so `hostid` is appended to the linux list only (see darwin/cosmo below).
      applets = [
        "[" "b2sum" "base32" "base64" "basename" "basenc" "cat" "chcon"
        "chgrp" "chmod" "chown" "chroot" "cksum" "comm" "cp" "csplit" "cut"
        "date" "dd" "df" "dir" "dircolors" "dirname" "du" "echo" "env"
        "expand" "expr" "factor" "false" "fmt" "fold" "groups" "head"
        "id" "install" "join" "kill" "link" "ln" "logname" "ls"
        "md5sum" "mkdir" "mkfifo" "mknod" "mktemp" "mv" "nice" "nl" "nohup"
        "nproc" "numfmt" "od" "paste" "pathchk" "pinky" "pr" "printenv"
        "printf" "ptx" "pwd" "readlink" "realpath" "rm" "rmdir" "runcon"
        "seq" "sha1sum" "sha224sum" "sha256sum" "sha384sum" "sha512sum"
        "shred" "shuf" "sleep" "sort" "split" "stat" "stty" "sum" "sync"
        "tac" "tail" "tee" "test" "timeout" "touch" "tr" "true" "truncate"
        "tsort" "tty" "uname" "unexpand" "uniq" "unlink" "uptime" "users"
        "vdir" "wc" "who" "whoami" "yes"
      ];
    in
    unpins-lib.lib.mkStandaloneFlake {
      inherit self;
      name = "coreutils";
      windowsBuild = import ./cosmo.nix { inherit unpins-lib; };

      # Cosmo (APE/Windows) multicall module for the mega, emitted from the
      # cosmo cross build above. No depArchives — cosmo disables acl/attr.
      multicallCosmo = {
        program = "coreutils";
        programObjs = [ "src/coreutils-coreutils.o" ];
        appletArchives = [ "src/libsinglebin_*.a" "src/libcksum_*.a" "src/libwc_*.a" "src/libver.a" ];
        gnulibArchives = [ "lib/libcoreutils.a" ];
        aliases = applets;
      };
      # coreutils dispatches by argv[0], but the Windows smoke runs the artifact
      # as `smoke.exe` → `unknown program 'smoke'`. `--unpin-program=env` picks
      # the applet explicitly regardless of argv[0].
      smoke = [ "--unpin-program=env" "--version" ];
      smokePattern = "GNU coreutils";

      engine = "unpin-llvm";
      multicall = {
        programs = [{
          name = "coreutils";
          aliases = applets ++ [ "hostid" ];
        }];
      };

      build = pkgs:
        let sp = pkgs.pkgsStatic; in
        unpins-lib.lib.withAliases pkgs
          {
            primary = "coreutils";
            aliasesFromSymlinksIn = "bin";
          }
          # No functionality is dropped, only redundant deps:
          #   acl/attr: off on darwin (nixpkgs acl/attr are Linux-only) but
          #     configure still auto-detects native ACL/xattr from libSystem.
          #   gmp: factor/expr fall back to gnulib's mini-gmp (also dodges a
          #     flaky gmp tests/mpq under musl pkgsStatic).
          #   openssl: md5sum/sha*sum keep gnulib impls — smaller closure.
          ((sp.coreutils.override {
            # minimal=false keeps $out/share/man (minimal=true rm's it), so
            # `unpin man coreutils <applet>` works. withOpenssl stays off below
            # so this doesn't default openssl on.
            minimal = false;
            aclSupport = pkgs.stdenv.hostPlatform.isLinux;
            attrSupport = pkgs.stdenv.hostPlatform.isLinux;
            selinuxSupport = false;
            gmpSupport = false;
            withOpenssl = false;
            singleBinary = "symlinks";
          }).overrideAttrs (old: {
            # Add unpins' uniform `--unpin-program=NAME` selector (a synonym of
            # coreutils' own `--coreutils-prog=`). See docs/multicall.md.
            patches = (old.patches or [ ]) ++ [ ./coreutils-unpin-program.patch ];

            # Restrict to tests/ (coreutils' own suite): the top-level check
            # also recurses into gnulib-tests/, whose threading/locale/TLS units
            # assume glibc and fail under musl. Cross skips via canExecute;
            # darwin-native off (not locally verifiable yet).
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
