{
  lib,
  pkgs,
  ...
}:
with lib; {
  home.packages = with pkgs; [
    fd
    # ripgrep-all
    ripgrep
    sd
  ];
}
