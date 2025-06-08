{
  lib,
  pkgs,
  ...
}:

{
  # Desktop-specific performance settings
  boot = {
    kernel.sysctl = {
      # Optimize for desktop workloads
      "vm.swappiness" = 60;  # More aggressive swapping for desktop
      "vm.vfs_cache_pressure" = 100;  # More aggressive cache pressure

      # Optimize for gaming
      "kernel.sched_autogroup" = 1;
      "kernel.sched_rr_timeslice_ms" = 1;
      "kernel.sched_rt_runtime_us" = 950000;
    };
  };

  # Desktop-specific services
  services = {
    # Enable performance governor for desktop
    power-profiles-daemon.enable = true;

    # Enable AMD GPU performance features
    amdgpu = {
      enable = true;
      powerManagement = {
        enable = true;
        dynamicPowerManagement = true;
      };
    };
  };

  # Desktop-specific packages
  environment.systemPackages = with pkgs; [
    # AMD GPU monitoring and control
    amdgpu_top
    radeontop
    rocm-smi  # ROCm System Management Interface

    # Performance monitoring
    corectrl  # GUI for CPU/GPU control
    gamemode  # Game mode optimization
  ];
}
