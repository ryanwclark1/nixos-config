{
  pkgs,
  config,
  ...
}:
{
  # Node Exporter - System metrics
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
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
      "uname"
      "vmstat"
      "logind"
      "interrupts"
      "ksmd"
      "processes"
      "systemd"
      "tcpstat"
      "wifi"
      "diskstats"
      "filefd"
      "hwmon"
      "infiniband"
      "ipvs"
      "mdadm"
      "meminfo_numa"
      "mountstats"
      "nfs"
      "nfsd"
      "sockstat"
      "stat"
      "textfile"
      "time"
      "uname"
      "vmstat"
      "xfs"
      "zfs"
    ];
  };

  # Systemd Exporter - Systemd service metrics
  services.prometheus.exporters.systemd = {
    enable = true;
    port = 9558;
    # unitWhitelist = [ ".*" ];
    # unitBlacklist = [ ".+\\.slice" ];
  };

  # cAdvisor - Container metrics (Docker, Kubernetes, etc.)
  services.cadvisor = {
    enable = true;
    port = 8080;
    listenAddress = "0.0.0.0";
  };

  # Process Exporter - Process metrics
  services.prometheus.exporters.process = {
    enable = true;
    port = 9256;
    settings.process_names = [
      "(node_exporter)"
      "(systemd_exporter)"
      "(cadvisor)"
      "(process_exporter)"
    ];
  };

  # Open firewall ports for all exporters on Tailscale interface
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [
      config.services.prometheus.exporters.node.port
      config.services.prometheus.exporters.systemd.port
      config.services.cadvisor.port
      config.services.prometheus.exporters.process.port
    ];
  };
}
