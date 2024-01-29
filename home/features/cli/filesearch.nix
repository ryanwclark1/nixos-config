{
  pkgs,
  lib,
  config,
  ...
}:

{
  home.packages = with pkgs; [
    fd #find alternative
    sd #sed alternative
  ];
  program.ripgrep = {
    enable = true;
    package = pkgs.ripgrep-all;
  };
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