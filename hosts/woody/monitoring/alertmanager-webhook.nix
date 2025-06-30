{
  pkgs,
  config,
  ...
}:

{
  # Create the webhook receiver script
  environment.etc."alertmanager/webhook-receiver.py" = {
    source = ./alertmanager-webhook-receiver.py;
    mode = "0755";
  };

  # Systemd service for the webhook receiver
  systemd.services.alertmanager-webhook = {
    description = "Alertmanager Webhook Receiver";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.python3}/bin/python3 /etc/alertmanager/webhook-receiver.py";
      Restart = "always";
      RestartSec = "10s";
      User = "alertmanager-webhook";
      Group = "alertmanager-webhook";
      
      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/var/log/alertmanager-webhook" ];
      
      # Logging
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "alertmanager-webhook";
    };

    environment = {
      PYTHONUNBUFFERED = "1";
      # Add any additional environment variables here
      # WEBHOOK_CONFIG = "/etc/alertmanager/webhook-config.yml";
    };
  };

  # Create user and group for the webhook service
  users.users.alertmanager-webhook = {
    isSystemUser = true;
    group = "alertmanager-webhook";
    description = "Alertmanager Webhook Receiver";
  };

  users.groups.alertmanager-webhook = {};

  # Create log directory
  systemd.tmpfiles.rules = [
    "d /var/log/alertmanager-webhook 0755 alertmanager-webhook alertmanager-webhook -"
  ];

  # Open firewall port for webhook receiver (if needed for external access)
  # networking.firewall.allowedTCPPorts = [ 5001 ];
}