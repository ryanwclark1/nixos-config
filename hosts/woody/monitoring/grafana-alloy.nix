{
  imports = [
    ../../common/optional/monitoring/grafana-alloy.nix
  ];

  services.alloy-unified = {
    enable = true;
    hostname = "woody";
    lokiEndpoint = "http://localhost:3100/loki/api/v1/push";
    prometheusEndpoint = "http://localhost:9090/api/v1/write";
    environment = "production";
    enableVolumeFilter = true; # woody has high log volume
    extraCapabilities = [ "CAP_NET_RAW" ]; # for network probing
  };
}