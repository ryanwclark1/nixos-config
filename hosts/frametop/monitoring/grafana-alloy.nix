{
  imports = [
    ../../common/optional/monitoring/grafana-alloy.nix
  ];

  services.alloy-unified = {
    enable = true;
    hostname = "frametop";
    lokiEndpoint = "http://woody:3100/loki/api/v1/push"; # Send to woody
    prometheusEndpoint = "http://woody:9090/api/v1/write";
    environment = "production";
    enableVolumeFilter = false; # frametop doesn't need aggressive filtering
  };
}