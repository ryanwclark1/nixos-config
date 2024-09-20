{
  pkgs
}:

pkgs.writeShellScriptBin "screenshootin" ''
  ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.swappy}/bin/swappy -f -
''
