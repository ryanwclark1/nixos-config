{
  pkgs,
  lib,
  config,
  ...
}:

{
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
  programs.zoxide = {
    enable = true;
  };
}