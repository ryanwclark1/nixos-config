{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Prometheus exporters for system monitoring
  services.prometheus = {
    exporters = {
      # Node exporter for system metrics
      node = {
        enable = lib.mkDefault true;
        enabledCollectors = [
          "cpu"
          "diskstats"
          "filesystem"
          "loadavg"
          "meminfo"
          "netdev"
          "netstat"
          "textfile"
          "time"
          "vmstat"
          "logind"
          "interrupts"
          "ksmd"
        ];
        extraFlags = [
          "--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)"
          "--collector.filesystem.ignored-fs-types=^(sys|proc|auto)fs$$"
        ];
      };

      # Process exporter for process metrics
      process = {
        enable = lib.mkDefault false;
        port = 9256;
      };

      # Blackbox exporter for network monitoring
      blackbox = {
        enable = lib.mkDefault false;
        port = 9115;
        configFile = pkgs.writeText "blackbox.yml" ''
          modules:
            http_2xx:
              prober: http
              timeout: 5s
              http:
                preferred_ip_protocol: "ip4"
            http_post_2xx:
              prober: http
              timeout: 5s
              http:
                method: POST
            tcp_connect:
              prober: tcp
              timeout: 5s
            icmp:
              prober: icmp
              timeout: 5s
              icmp:
                preferred_ip_protocol: "ip4"
        '';
      };
    };
  };

  # System monitoring packages
  environment.systemPackages = with pkgs; [
    # System monitoring tools
    htop
    iotop
    nethogs
    smartmontools
    lm_sensors

    # Performance analysis
    sysstat
    perf-tools

    # Network monitoring
    iftop
    nload
    nethogs
  ];
}
