{
  pkgs,
  config,
  ...
}:
{
  services.prometheus.alertmanager = {
    enable = true;
    port = 9093;
    webExternalUrl = "http://woody:9093/";

    configuration = {
      global = {
        smtp_smarthost = "localhost:587";
        smtp_from = "alertmanager@woody";
      };

      route = {
        group_by = [
          "alertname"
          "cluster"
          "service"
        ];
        group_wait = "30s";
        group_interval = "5m";
        repeat_interval = "4h";
        receiver = "web.hook";
      };

      receivers = [
        {
          name = "web.hook";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/";
            }
          ];
        }
      ];

      inhibit_rules = [
        {
          source_match = {
            severity = "critical";
          };
          target_match = {
            severity = "warning";
          };
          equal = [
            "alertname"
            "dev"
            "instance"
          ];
        }
      ];
    };
  };

  # Open firewall for Alertmanager
  networking.firewall.allowedTCPPorts = [ 9093 ];
}
