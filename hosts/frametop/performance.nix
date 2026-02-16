{
  lib,
  pkgs,
  ...
}:

{
  # Laptop-specific boot optimizations
  boot = {
    # Laptop-specific sysctl overrides
    kernel.sysctl = {
      # Less aggressive swapping for laptop
      "vm.swappiness" = lib.mkOverride 50 10;
      "vm.vfs_cache_pressure" = lib.mkOverride 50 50;
      # Laptop-specific scheduler tweaks
      "kernel.sched_autogroup" = 0;
      "kernel.sched_rr_timeslice_ms" = 4;
    };

    # Framework-specific kernel parameters
    kernelParams = [
      # Consider removing this unless you need it for a specific quirk:
      # "acpi_osi=Linux"

      # ✅ Use native Intel backlight
      "acpi_backlight=native"
      "video.use_native_backlight=1"
      "mem_sleep_default=deep"

      "i915.fastboot=1"
      "i915.enable_guc=2"
      "i915.enable_fbc=1"
      "i915.enable_psr=1"
    ];

    # Enable early KMS for faster graphics initialization
    kernelModules = [ "i915" ];
  };

  # Enable thermal management for laptop
  services.thermald.enable = true;

  # Laptop-specific packages (if not already in global)
  environment.systemPackages = with pkgs; [
    # powertop  # Disabled: service crashes with segfault, use auto-cpufreq instead
    mission-center
  ];
}
