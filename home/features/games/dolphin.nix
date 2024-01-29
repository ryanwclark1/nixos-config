{
  lib,
  pkgs,
  ...
}:

{
  home = {
    packages = [ pkgs.dolphinEmu ];
  };
}