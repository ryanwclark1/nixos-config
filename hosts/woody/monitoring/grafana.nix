{
  pkgs,
  config,
  ...
}:
{
  services.grafana = {
    enable = true;
    settings = {

      # Server settings
      server = {
        http_port = 3001;
        http_addr = "0.0.0.0";
        domain = "woody";
        root_url = "http://woody:3001/";
      };

      # Security settings
      security = {
        adminUser = "admin";
        adminPassword = "admin"; # Change this in production!
      };

      # Database settings (using SQLite for simplicity)
      database = {
        # type = "sqlite3";
        path = "${config.services.grafana.dataDir}/grafana.db";
      };
    };

    # Provisioning
    provision = {
      enable = true;
      datasources = {
        settings = {
          apiVersion = 1;
          datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://localhost:9090";
              access = "proxy";
              isDefault = true;
            }
            {
              name = "Loki";
              type = "loki";
              url = "http://localhost:3100";
              access = "proxy";
            }
          ];
        };
      };

      # Pre-configure useful dashboards
      dashboards = {
        settings = {
          apiVersion = 1;
          providers = [
            {
              name = "default";
              orgId = 1;
              folder = "";
              type = "file";
              disableDeletion = false;
              updateIntervalSeconds = 10;
              allowUiUpdates = true;
              options = {
                path = "/var/lib/grafana/dashboards";
              };
            }
          ];
        };
      };
    };
  };

  # Create dashboard directory and copy dashboard files
  systemd.services.grafana.preStart = ''
    mkdir -p /var/lib/grafana/dashboards

    # Copy all dashboard JSON files
    cp ${./dashboards}/*.json /var/lib/grafana/dashboards/

    # Set proper permissions
    chown -R grafana:grafana /var/lib/grafana/dashboards
    chmod 644 /var/lib/grafana/dashboards/*.json
  '';

  # Open firewall for Grafana
  networking.firewall.allowedTCPPorts = [ 3001 ];
}
