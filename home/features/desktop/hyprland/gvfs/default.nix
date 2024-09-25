# GVFS used with 
{
  pkgs,
  ...
}:

{
  services.gvfs = {
    enable = true;
    package = pkgs.gvfs;
  }
}