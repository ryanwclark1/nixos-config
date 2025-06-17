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
    # Enable thermal management
    thermald.enable = true;
  };

  # Laptop-specific packages
  environment.systemPackages = with pkgs; [
    # Power management
    powertop

    # Temperature monitoring
    mission-center  # Replaced psensor (removed from nixpkgs)
    s-tui

    # Battery monitoring
    acpi
    upower
  ];
}
