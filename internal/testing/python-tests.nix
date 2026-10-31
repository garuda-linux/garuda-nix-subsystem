{ pkgs }:
let
  inherit (pkgs) lib;

  dirs = [
    "garuda-installer-lib"
    "garuda-update"
    "gns-management"
  ];

  # gns-management imports garuda-installer-lib from its sibling directory
  src = lib.fileset.toSource {
    root = ../../packages;
    fileset = lib.fileset.unions (map (dir: ../../packages + "/${dir}") dirs);
  };

  python = pkgs.python3.withPackages (ps: [
    ps.tree-sitter
    ps.tree-sitter-grammars.tree-sitter-nix
  ]);

  unittest =
    dir:
    pkgs.runCommand "${dir}-tests"
      {
        nativeBuildInputs = [
          pkgs.git
          python
        ];
      }
      ''
        export HOME=$TMPDIR
        cp -r ${src} src
        chmod -R u+w src
        cd src/${dir}
        python3 -m unittest discover -s . -p 'test_*.py'
        touch $out
      '';
in
lib.listToAttrs (
  map (dir: {
    name = "${dir}-tests";
    value = unittest dir;
  }) dirs
)
