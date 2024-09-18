{
  lib,
  pkgs,
  ...
}:

with lib; {
  home.packages = with pkgs; [
    jdupes
    ncdu # TUI disk usage
  ];
}
