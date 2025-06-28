{
  pkgs,
  config,
  ...
}:
{
  services.prometheus = {
    enable = true;
    port = 9090;
    
    # Enable remote write receiver
    extraFlags = [
      "--web.enable-remote-write-receiver"
      "--enable-feature=remote-write-receiver"
    ];
    
    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "15s";
    };

    # Alertmanager configuration
    alertmanagers = [
      {
        static_configs = [
          {
            targets = [ "localhost:9093" ];
          }
        ];
      }
    ];

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
      
      # Alertmanager monitoring
      {
        job_name = "alertmanager";
        static_configs = [
          {
            targets = [ "localhost:9093" ];
          }
        ];
      }
      
      # Alloy self-monitoring (even though metrics are sent via remote write, we still want to monitor Alloy health)
      {
        job_name = "alloy";
        static_configs = [
          {
            targets = [ "localhost:12345" ];
            labels = {
              instance = "woody";
            };
          }
        ];
      }
    ];

    # Alert rules
    ruleFiles = [
      ./grafana/provisioning/alerting/rules/alloy-health.yml
      ./grafana/provisioning/alerting/rules/system-metrics.yml
      ./grafana/provisioning/alerting/rules/network-monitoring.yml
      # ./grafana/provisioning/alerting/rules/log-monitoring.yml  # This contains LogQL queries for Loki, not PromQL
      ./grafana/provisioning/alerting/rules/container-metrics.yml
    ];
    
    # Enable web interface
    webExternalUrl = "http://woody:9090/";
  };

  # Open firewall for Prometheus
  networking.firewall.allowedTCPPorts = [ 9090 ];
}
