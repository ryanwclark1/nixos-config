{
  pkgs,
  ...
}:

{
  programs.nushell = {
    enable = true;
    package = pkgs.nushell;
  };
}