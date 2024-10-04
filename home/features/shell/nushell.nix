{
  pkgs,
  ...
}:

{
  programs.nushell = {
    enable = false;
    package = pkgs.nushell;
  };
}