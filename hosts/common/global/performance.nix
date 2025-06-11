{
  lib,
  pkgs,
  ...
}:

{
  # Global performance settings
  boot = {
    # Additional kernel performance settings
    kernel.sysctl = {
      # Memory management
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_ratio" = 10;
      "vm.dirty_background_ratio" = 5;
      "vm.dirty_expire_centisecs" = 1000;
      "vm.dirty_writeback_centisecs" = 100;

      # Network performance
      "net.core.somaxconn" = 65535;
      "net.core.netdev_max_backlog" = 262144;
      "net.ipv4.tcp_max_syn_backlog" = 262144;
      "net.ipv4.tcp_slow_start_after_idle" = 0;
      "net.ipv4.tcp_keepalive_time" = 60;
      "net.ipv4.tcp_keepalive_intvl" = 10;
      "net.ipv4.tcp_keepalive_probes" = 6;

      # File system performance
      "fs.file-max" = 2097152;
      "fs.inotify.max_user_watches" = 1048576;
      "fs.inotify.max_user_instances" = 1024;
    };
  };

  # Enable performance-related services
  services = {
    # Enable fstrim for SSD optimization
    fstrim.enable = true;

    # Enable systemd-oomd for better memory management
    systemd-oomd.enable = true;

    # Enable irqbalance for better CPU interrupt handling
    irqbalance.enable = true;
  };

  # Performance-related system packages
  environment.systemPackages = with pkgs; [
    # System monitoring
    btop  # Modern system monitor
    iotop
    nethogs
    smartmontools
    lm_sensors

    # Performance analysis
    sysstat
    perf-tools
    ftrace
  ];
}
