{
  pkgs,
  lib,
  ...
}:

{
  boot = {
    # Common boot loader configuration
    loader = {
      timeout = lib.mkDefault 3;
      systemd-boot = {
        enable = lib.mkDefault true;
        consoleMode = "keep";
        # Enable secure boot support (uncomment to enable)
        # Must run setup-secureboot.sh to generate keys
        # secureBoot = {
        #   enable = true;
        #   keyDir = "/etc/secureboot";
        # };
        # Limit number of entries to keep
        # Default: 10 entries - good balance between rollback capability and disk space
        # - Provides enough history for safe rollbacks
        # - Keeps disk usage reasonable
        # - Can be overridden per host for specific needs (e.g., desktop vs laptop)
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = lib.mkDefault true;
    };

    # Common kernel settings
    kernelPackages = pkgs.linuxKernel.packages.linux_6_18;

    # Enable systemd in initrd for better boot process
    initrd = {
      systemd.enable = lib.mkDefault true;
      # Enable verbose output for debugging
      verbose = lib.mkDefault false;
      # Enable network support in initrd (useful for remote unlocking)
      network.enable = lib.mkDefault false;
      # Enable SSH in initrd for remote unlocking (optional)
      # network.ssh.enable = true;
    };

    # Consolidated kernel sysctl settings
    kernel.sysctl = {
      # Security settings
      "kernel.sysrq" = 0; # Disable magic SysRQ
      "kernel.core_uses_pid" = 1;
      "kernel.ctrl-alt-del" = 0;
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
      "kernel.yama.ptrace_scope" = 1;
      "kernel.perf_event_paranoid" = 2;

      # Network security
      "net.ipv4.tcp_syncookies" = 1;
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.default.rp_filter" = 1;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;

      # Memory management (can be overridden by performance module)
      "vm.swappiness" = lib.mkDefault 10;
      "vm.vfs_cache_pressure" = lib.mkDefault 50;
      "vm.dirty_ratio" = 10;
      "vm.dirty_background_ratio" = 5;
      "vm.dirty_expire_centisecs" = 1000;
      "vm.dirty_writeback_centisecs" = 100;

      # Network performance
      "net.core.somaxconn" = 65535;
      "net.core.netdev_max_backlog" = 262144;
      "net.core.rmem_max" = 134217728;
      "net.core.wmem_max" = 134217728;
      "net.ipv4.tcp_max_syn_backlog" = 262144;
      "net.ipv4.tcp_rmem" = "4096 87380 134217728";
      "net.ipv4.tcp_wmem" = "4096 65536 134217728";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_slow_start_after_idle" = 0;
      "net.ipv4.tcp_keepalive_time" = 60;
      "net.ipv4.tcp_keepalive_intvl" = 10;
      "net.ipv4.tcp_keepalive_probes" = 6;
      "net.ipv4.tcp_tw_reuse" = 1;
      "net.ipv4.ip_local_port_range" = "1024 65535";

      # IPv6 optimizations
      "net.ipv6.conf.all.accept_ra" = 2;
      "net.ipv6.conf.default.accept_ra" = 2;
      "net.ipv6.conf.all.autoconf" = 1;
      "net.ipv6.conf.default.autoconf" = 1;

      # File system performance
      "fs.file-max" = 2097152;
      "fs.inotify.max_user_watches" = 1048576;
      "fs.inotify.max_user_instances" = 1024;

      # Real-time scheduling (can be overridden per host)
      "kernel.sched_rt_runtime_us" = 950000;
    };

    # Enable kernel hardening
    kernelParams = [
      # Security hardening
      "slab_nomerge"
      "slub_debug=FZP"
      "pti=on"
      "vsyscall=none"
      "debugfs=off"
      "oops=panic"
      "module.sig_unenforce=1"

      # Performance
      "mitigations=off" # Can be enabled for better security
      "quiet"
      "loglevel=3"
    ];
  };
}
