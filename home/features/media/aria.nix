{
  pkgs,
  ...
}:

{
  programs.aria2c = {
    enable = true;
    package = pkgs.aria2;
  };
}