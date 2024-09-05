# An interactive cheatsheet tool for the command-line
{
  pkgs,
  ...
}:

{
  programs.navi = {
    enable = true;
    package = pkgs.navi;
  };
}