{
  pkgs,
  ...
}:

{
  services = {
    spice-vdagentd.enable = true;
    spice-webdavd = {
      enable = true;
      package = pkgs.spice-webdavd;
    };
    spice-autorandr = {
      enable = true;
      package = pkgs.spice-autorandr;
    };
  };
}
