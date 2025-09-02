# Systemd-resolved configuration fixes
{
  config,
  lib,
  ...
}:

{
  # Ensure systemd-resolved starts before services that need DNS
  systemd.services.systemd-resolved = {
    before = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" "network-online.target" ];
    # Ensure it starts early in boot
    after = [ "systemd-networkd.service" ];
    serviceConfig = {
      # Add retry logic for robustness
      Restart = "on-failure";
      RestartSec = "2s";
      StartLimitBurst = 5;
      StartLimitIntervalSec = 30;
    };
  };

  # Create symlink for /etc/resolv.conf if it doesn't exist
  systemd.tmpfiles.rules = [
    "L /etc/resolv.conf - - - - /run/systemd/resolve/stub-resolv.conf"
  ];

  # Ensure DNS is working before network is considered online
  systemd.services.systemd-resolved-wait = {
    description = "Wait for systemd-resolved to be ready";
    after = [ "systemd-resolved.service" ];
    before = [ "network-online.target" ];
    wantedBy = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${config.systemd.package}/bin/systemctl is-active systemd-resolved.service";
      Restart = "on-failure";
      RestartSec = "1s";
      StartLimitBurst = 10;
      StartLimitIntervalSec = 30;
    };
  };
}