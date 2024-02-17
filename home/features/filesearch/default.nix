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
  programs.eza = {
    enable = true;
    icons = true;
    git = true;
    enableAliases = true;
  };
}
