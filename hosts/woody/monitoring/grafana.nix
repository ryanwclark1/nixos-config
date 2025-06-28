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
  environment.etc."grafana/dashboards/default/enhanced-alloy-overview.json" = {
    source = ./grafana/dashboards/default/enhanced-alloy-overview.json;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };
  environment.etc."grafana/dashboards/default/security-monitoring.json" = {
    source = ./grafana/dashboards/default/security-monitoring.json;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };
  environment.etc."grafana/dashboards/default/network-monitoring.json" = {
    source = ./grafana/dashboards/default/network-monitoring.json;
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
  environment.etc."grafana/dashboards/default/multi-host-logs.json" = {
    source = ./grafana/dashboards/default/multi-host-logs.json;
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

  # Alerting rules
  environment.etc."grafana/provisioning/alerting/rules/alloy-health.yml" = {
    source = ./grafana/provisioning/alerting/rules/alloy-health.yml;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };
  environment.etc."grafana/provisioning/alerting/rules/system-metrics.yml" = {
    source = ./grafana/provisioning/alerting/rules/system-metrics.yml;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };
  environment.etc."grafana/provisioning/alerting/rules/container-metrics.yml" = {
    source = ./grafana/provisioning/alerting/rules/container-metrics.yml;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };
  environment.etc."grafana/provisioning/alerting/rules/network-monitoring.yml" = {
    source = ./grafana/provisioning/alerting/rules/network-monitoring.yml;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };
  environment.etc."grafana/provisioning/alerting/rules/log-monitoring.yml" = {
    source = ./grafana/provisioning/alerting/rules/log-monitoring.yml;
    mode = "0750";
    user = "grafana";
    group = "grafana";
  };
  environment.etc."grafana/provisioning/alerting/prometheus.yml" = {
    source = ./grafana/provisioning/alerting/prometheus.yml;
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

      # Unified alerting (Grafana 9+)
      unified_alerting = {
        enabled = true;
        execute_alerts = true;
        evaluation_timeout = "30s";
        notification_timeout = "30s";
        max_attempts = 3;
      };

      # Security settings
    };

    # Provisioning
    provision = {
      enable = true;

      datasources.settings = {
        apiVersion = 1;
        deleteDatasources = [];
        datasources = [];
      };

      dashboards.settings = {
        apiVersion = 1;
        providers = [{
          name = "default";
          orgId = 1;
          folder = "";
          type = "file";
          disableDeletion = false;
          updateIntervalSeconds = 10;
          allowUiUpdates = true;
          options = {
            path = "/etc/grafana/dashboards/default";
          };
        }];
      };
    };
  };

  # Open firewall for Grafana
  networking.firewall.allowedTCPPorts = [ 3001 ];
}
