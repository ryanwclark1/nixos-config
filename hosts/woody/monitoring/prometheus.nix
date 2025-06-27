{
  pkgs,
  config,
  ...
}:
{
  services.prometheus = {
    enable = true;
    port = 9090;
    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "15s";
    };

    # Alertmanager configuration
    alertmanager = {
      enable = true;
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

    scrapeConfigs = [
      # Self-monitoring
      {
        job_name = "prometheus";
        static_configs = [
          {
            targets = [ "localhost:9090" ];
          }
        ];
      }
      
      # Alloy metrics on woody
      {
        job_name = "woody-alloy";
        static_configs = [
          {
            targets = [ "localhost:12345" ];
          }
        ];
      }
      # Alloy metrics on frametop (via Tailscale)
      {
        job_name = "frametop-alloy";
        static_configs = [
          {
            targets = [ "frametop:12345" ];
          }
        ];
      }
    ];

    # Enable web interface
    webExternalUrl = "http://woody:9090/";
  };

  # Open firewall for Prometheus
  networking.firewall.allowedTCPPorts = [ 9090 ];
}
