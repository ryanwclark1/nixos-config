{
  pkgs,
  config,
  lib,
  ...
}:
# let
#   # Helper function to create secure directories
#   createSecureDir = path: {
#     "${path}" = {
#       mode = "0750";
#       user = "alloy";
#       group = "alloy";
#     };
#   };
# in
{
  # Create the Alloy configuration file with enhanced features
  environment.etc."alloy/config.alloy" = {
    source = ./alloy/config.alloy;
    # mode = "0770";
    # user = "alloy";
    # group = "alloy";
  };

  environment.etc."alloy/blackbox.yml" = {
    source = ./alloy/blackbox.yml;
    # mode = "0644";
    # user = "root";
    # group = "root";
  };

  environment.etc."alloy/snmp.yml" = {
    source = ./alloy/snmp.yml;
    # mode = "0644";
    # user = "root";
    # group = "root";
  };

  services.alloy = {
    enable = true;
    configPath = "/etc/alloy";
    extraFlags = [
      "--disable-reporting"
    ];
  };

  # Create alloy user and group with enhanced security
  # users.users.alloy = {
  #   isSystemUser = true;
  #   group = "alloy";
  #   home = "/var/lib/alloy";
  #   createHome = true;
  #   shell = "${pkgs.bash}/bin/bash";
  #   extraGroups = [
  #     "systemd-journal"
  #     "docker"
  #   ];
  # };

  # users.groups.alloy = { };

  # Create necessary directories with proper permissions
  # systemd.tmpfiles.rules = [
  #   # Main data directory
  #   "d /var/lib/alloy 0750 alloy alloy -"
  #   "d /var/lib/alloy/positions 0750 alloy alloy -"
  #   "d /var/lib/alloy/cache 0750 alloy alloy -"
  #   "d /var/lib/alloy/tmp 0750 alloy alloy -"

  #   # Log directory
  #   "d /var/log/alloy 0750 alloy alloy -"

  #   # Config directory
  #   "d /etc/alloy 0750 alloy alloy -"
  # ];

  # Create custom systemd service for Alloy with enhanced configuration
  # systemd.services.alloy = {
  #   description = "Grafana Alloy - Log Collection Agent";
  #   documentation = [ "https://grafana.com/docs/alloy/" ];
  #   wantedBy = [ "multi-user.target" ];
  #   after = [
  #     "network.target"
  #     "docker.service"
  #   ];
  #   wants = [ "network.target" ];
  #   enable = true;

  #   serviceConfig = {
  #     Type = "simple";
  #     User = "alloy";
  #     Group = "alloy";
  #     WorkingDirectory = "/var/lib/alloy";
  #     ExecStart = "${pkgs.grafana-alloy}/bin/alloy run /etc/alloy/config.alloy";
  #     ExecReload = "${pkgs.util-linux}/bin/kill -HUP $MAINPID";
  #     Restart = "always";
  #     RestartSec = "10";
  #     # StartLimitInterval = "60s";
  #     StartLimitBurst = "3";
  #     StandardOutput = "journal";
  #     StandardError = "journal";
  #     SyslogIdentifier = "alloy";

  #     # Security settings
  #     NoNewPrivileges = true;
  #     ProtectSystem = "strict";
  #     ProtectHome = true;
  #     ReadWritePaths = [
  #       "/var/lib/alloy"
  #       "/var/log"
  #       "/var/lib/docker"
  #       "/proc"
  #       "/sys"
  #     ];
  #     PrivateTmp = true;
  #     PrivateDevices = true;
  #     ProtectKernelTunables = true;
  #     ProtectKernelModules = true;
  #     ProtectControlGroups = true;
  #     RestrictRealtime = true;
  #     RestrictSUIDSGID = true;
  #     LockPersonality = true;
  #     MemoryDenyWriteExecute = true;

  #     # Resource limits
  #     LimitNOFILE = "65536";
  #     LimitNPROC = "4096";

  #     # Environment variables
  #     Environment = [
  #       "ALLOY_HOME=/var/lib/alloy"
  #       "ALLOY_CONFIG=/etc/alloy/config.alloy"
  #     ];
  #   };

  #   # Service dependencies
  #   unitConfig = {
  #     RequiresMountsFor = "/var/log /var/lib/docker";
  #   };
  # };

  # Add Alloy to the monitoring group for access to system metrics
  # users.groups.monitoring = {
  #   members = [ "alloy" ];
  # };

  # Create logrotate configuration for Alloy logs
  # services.logrotate.settings.alloy = {
  #   files = "/var/log/alloy/*.log";
  #   compress = true;
  #   copytruncate = true;
  #   daily = true;
  #   rotate = 7;
  #   missingok = true;
  #   notifempty = true;
  #   create = "0640 alloy alloy";
  # };

  # Open firewall for Alloy
  networking.firewall.allowedTCPPorts = [ 12345 ];
}
