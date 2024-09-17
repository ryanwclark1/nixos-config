{
  pkgs,
  ...
}:

{
  services = {
    fwupd = {
      enable = true;
      package = pkgs.fwupd;
    };
  };
}