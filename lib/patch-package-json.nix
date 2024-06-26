{ file
, lib
, pkgs
, nodejs
, extract-node-version
, packageManager
, handlePrisma
}:


let
  jq = "${pkgs.jq}/bin/jq";

  patchDependency = name: version: lib.concatStringsSep " " [
    ''if .dependencies."${name}"''
    ''then .dependencies."${name}" = "${version}"''
    ''elif .devDependencies."${name}"''
    ''then .devDependencies."${name}" = "${version}"''
    ''end''
  ];

  patchDependencyPrefix = prefix: version:
    let
      patchInObject = obj: lib.concatStringsSep " " [
        ''if .${obj}''
        ''then .${obj} = .${obj} + ( .${obj} | with_entries( select( .key | startswith( "${prefix}" ) ) ) | map_values( "${version}" ) )''
        ''end''
      ];

    in

    lib.concatStringsSep " | " [
      (patchInObject "dependencies")
      (patchInObject "devDependencies")
    ];

  patchPackageManager = ''if .packageManager then .packageManager = "${lib.getName packageManager}@${lib.getVersion packageManager}" end'';

  patchEngines = [
    ''if .engines.node then .engines.node = "${extract-node-version (lib.getVersion nodejs)}" end''
    ''if .engines.npm then .engines.npm = "${lib.getVersion nodejs.pkgs.npm}" end''
  ] ++ lib.optionals (packageManager != null) [
    ''if .engines."${lib.getName packageManager}" then .engines."${lib.getName packageManager}" = "${lib.getVersion packageManager}" end''
  ];

  filters =
    [
      (patchDependency "@types/node" (extract-node-version (lib.getVersion nodejs)))
    ] ++
    (lib.optionals handlePrisma [
      (patchDependencyPrefix "@prisma/" (lib.getVersion nodejs.pkgs.prisma))
      (patchDependency "prisma" (lib.getVersion nodejs.pkgs.prisma))
    ]) ++
    (lib.optionals (packageManager != null) [ patchPackageManager ]) ++
    patchEngines;

in

''
  if ${jq} . ${file} >/dev/null 2>&1; then
    tmp=$(mktemp)
    ${jq} '${lib.concatStringsSep " | " filters}' ${file} > $tmp
    mv $tmp ${file}
  fi
''
