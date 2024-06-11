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
      patchPackageJson = import ../lib/patch-package-json.nix;

    in

    {
      devenv.shells.${devShellName} =
        { config
        , ...
        }:

        let
          cfg = config.languages.javascript;

        in

        {
          options.languages.javascript = {
            packageManager = lib.mkOption {
              type = lib.types.nullOr (lib.types.oneOf [ lib.types.package (lib.types.enum [ "yarn" "pnpm" ]) ]);
              default = null;
              apply = lib.mapNullable (arg:
                if builtins.typeOf arg == "string" then
                  cfg.package.pkgs.${arg}
                else
                  arg
              );
            };

            handlePrisma = lib.mkEnableOption { };

            patchPackageJsonFiles = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  extract-node-version = lib.mkOption {
                    type = lib.types.addCheck lib.types.anything (x: builtins.typeOf x == "lambda");
                    default = lib.id;
                  };

                  files = lib.mkOption {
                    type = lib.types.listOf (lib.types.path);
                    apply = builtins.map (f: config.env.DEVENV_ROOT + f);
                    default = [ ];
                  };
                };
              };

              default = { };
            };
          };

          config = lib.mkIf cfg.enable {
            packages = lib.flatten [
              (lib.optionals (cfg.packageManager != null) [ cfg.packageManager ])

              (lib.optionals cfg.handlePrisma [
                cfg.package.pkgs.prisma
                pkgs.openssl
                pkgs.pkg-config
              ])
            ];

            env = lib.mkIf cfg.handlePrisma {
              PRISMA_QUERY_ENGINE_LIBRARY = "${pkgs.prisma-engines}/lib/libquery_engine.node";
              PRISMA_SCHEMA_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/schema-engine";
            };

            enterShell =
              let
                patch = file: patchPackageJson {
                  inherit file lib pkgs;
                  inherit (cfg) packageManager handlePrisma;
                  nodejs = cfg.package;
                  inherit (cfg.patchPackageJsonFiles) extract-node-version;
                };

              in

              lib.concatMapStringsSep "\n\n" patch cfg.patchPackageJsonFiles.files;
          };
        };
    };
}
