{
  imports = [
    ./prometheus.nix
    ./grafana.nix
    ./alertmanager.nix
    ./exporters.nix
    ./loki.nix
    ../../common/global/monitoring/grafana-alloy.nix
  ];
}
