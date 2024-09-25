# GVFS used with AGS
{
  pkgs,
  ...
}:

{
  services.gvfs = {
    enable = true;
    package = pkgs.gvfs;
  };
}