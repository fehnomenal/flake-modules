{ devShellName
}:

{ lib
, ...
}:

{
  perSystem =
    { pkgs
    , ...
    }:

    let
      sed = "${pkgs.busybox}/bin/sed";

    in

    {
      devenv.shells.${devShellName} =
        { config
        , ...
        }:

        let
          cfg = config.replaceInFile;

        in

        {
          options.replaceInFile = lib.mkOption {
            type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
            default = { };
          };

          config = lib.mkIf (builtins.length (lib.attrNames cfg) != 0) {
            enterShell =
              let
                mapFile = file: repls: ''
                  ${sed} -i -E ${lib.concatStringsSep " " (lib.mapAttrsToList mapRepl repls)} ${config.env.DEVENV_ROOT + file}
                '';

                mapRepl = search: repl: ''-e "s|${search}|${repl}|"'';

              in
              lib.concatStringsSep "\n" (lib.attrsets.mapAttrsToList mapFile cfg);
          };
        };
    };
}
