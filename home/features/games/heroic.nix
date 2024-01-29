{
  lib,
  pkgs,
  ...
}:
{
  home = {
    packages = [ pkgs.heroic ];
  };
}
