{
  pkgs,
  config,
  ...
}:
{
  environment.etc."grafana/dashboards/default/alloy-overview.json" = {
    source = ./grafana/dashboards/default/alloy-overview.json;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };
  environment.etc."grafana/dashboards/default/enhanced-container-monitoring.json" = {
    source = ./grafana/dashboards/default/enhanced-container-monitoring.json;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };
  environment.etc."grafana/dashboards/default/log-exploration.json" = {
    source = ./grafana/dashboards/default/log-exploration.json;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };
  environment.etc."grafana/dashboards/default/multi-machine-dashboard.json" = {
    source = ./grafana/dashboards/default/multi-machine-dashboard.json;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };
  environment.etc."grafana/dashboards/default/overview-dashboard.json" = {
    source = ./grafana/dashboards/default/overview-dashboard.json;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };
  environment.etc."grafana/dashboards/default/docker-monitoring.json" = {
    source = ./grafana/dashboards/default/docker-monitoring.json;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };
  environment.etc."grafana/dashboards/default/enhanced-node-exporter.json" = {
    source = ./grafana/dashboards/default/enhanced-node-exporter.json;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };
  environment.etc."grafana/dashboards/default/multi-host-logs.json" = {
    source = ./grafana/dashboards/default/multi-host-logs.json;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };
  environment.etc."grafana/dashboards/default/node-exporter.json" = {
    source = ./grafana/dashboards/default/node-exporter.json;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };
  environment.etc."grafana/dashboards/default/process-monitoring.json" = {
    source = ./grafana/dashboards/default/process-monitoring.json;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };
  environment.etc."grafana/dashboards/default/systemd-services.json" = {
    source = ./grafana/dashboards/default/systemd-services.json;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };

  environment.etc."grafana/provisioning/dashboards/dashboards.yml" = {
    source = ./grafana/provisioning/dashboards/dashboards.yml;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };

  environment.etc."grafana/provisioning/datasources/datasources.yml" = {
    source = ./grafana/provisioning/datasources/datasources.yml;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };


  services.grafana = {
    enable = true;
    dataDir = "/var/lib/grafana";
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

      paths = {
        plugins = "${config.services.grafana.dataDir}/plugins";
        provisioning = "/etc/grafana/provisioning";
      };

      # Analytics settings
      analytics = {
        check_for_plugin_updates = false;
        reporting_enabled = false;
        check_for_updates = false;
        feedback_links_enabled = false;
      };

      # Security settings
    };

    # Provisioning
    provision = {
      enable = true;

      datasources = {
        path = "/etc/grafana/provisioning/datasources";
      };

      dashboards = {
        path = "/etc/grafana/dashboards";
      };
    };
  };

  # # Create dashboard directory with proper permissions
  # systemd.tmpfiles.rules = [
  #   "d /var/lib/grafana/dashboards 0755 grafana grafana -"
  # ];

  # # Copy dashboard files from the dashboards directory
  # systemd.services.grafana.preStart = ''
  #   mkdir -p /var/lib/grafana/dashboards
  #   cp ${./dashboards}/*.json /var/lib/grafana/dashboards/
  #   chown -R grafana:grafana /var/lib/grafana/dashboards
  # '';

  # Open firewall for Grafana
  networking.firewall.allowedTCPPorts = [ 3001 ];
}
