{
  pkgs,
  ...
}:

{
  services.fwupd = {
    enable = true;
    package = pkgs.fwupd;
  };

  systemd.services.fwupd-refresh.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "30s";
  };
}
