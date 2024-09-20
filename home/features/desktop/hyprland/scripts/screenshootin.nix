{
  pkgs
}:

pkgs.writeShellScriptBin "screenshootin" ''
  grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.swappy}/bin/swappy) -f -
''
