{
  lib,
  pkgs,
  ...
}:

{
  # Laptop-specific performance settings
  boot = {
    kernel.sysctl = {
      # Optimize for laptop workloads
      "vm.swappiness" = 10;  # Less aggressive swapping for laptop
      "vm.vfs_cache_pressure" = 50;  # Less aggressive cache pressure

      # Optimize for battery life
      "kernel.sched_autogroup" = 0;
      "kernel.sched_rr_timeslice_ms" = 4;
      "kernel.sched_rt_runtime_us" = 950000;
    };
  };

  # Laptop-specific services
  services = {
    # Enable power management
    power-profiles-daemon.enable = true;
    thermald.enable = true;
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 80;
      };
    };
  };

  # Laptop-specific packages
  environment.systemPackages = with pkgs; [
    # Power management
    powertop
    tlp

    # Temperature monitoring
    psensor
    s-tui

    # Battery monitoring
    acpi
    upower
  ];
}
