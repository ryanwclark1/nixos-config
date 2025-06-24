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
      # Node exporter on woody
      {
        job_name = "woody-node";
        static_configs = [
          {
            targets = [ "localhost:9100" ];
          }
        ];
      }
      # Node exporter on frametop (via Tailscale)
      {
        job_name = "frametop-node";
        static_configs = [
          {
            targets = [ "frametop:9100" ];
          }
        ];
      }
      # Systemd exporter on woody
      {
        job_name = "woody-systemd";
        static_configs = [
          {
            targets = [ "localhost:9558" ];
          }
        ];
      }
      # Systemd exporter on frametop (via Tailscale)
      {
        job_name = "frametop-systemd";
        static_configs = [
          {
            targets = [ "frametop:9558" ];
          }
        ];
      }
      # cAdvisor on woody
      {
        job_name = "woody-cadvisor";
        static_configs = [
          {
            targets = [ "localhost:8080" ];
          }
        ];
      }
      # cAdvisor on frametop (via Tailscale)
      {
        job_name = "frametop-cadvisor";
        static_configs = [
          {
            targets = [ "frametop:8080" ];
          }
        ];
      }
      # Network exporter on woody
      {
        job_name = "woody-network";
        static_configs = [
          {
            targets = [ "localhost:9107" ];
          }
        ];
      }
      # Network exporter on frametop (via Tailscale)
      {
        job_name = "frametop-network";
        static_configs = [
          {
            targets = [ "frametop:9107" ];
          }
        ];
      }
      # Process exporter on woody
      {
        job_name = "woody-process";
        static_configs = [
          {
            targets = [ "localhost:9256" ];
          }
        ];
      }
      # Process exporter on frametop (via Tailscale)
      {
        job_name = "frametop-process";
        static_configs = [
          {
            targets = [ "frametop:9256" ];
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
