{
  lib,
  pkgs,
  ...
}:

{
  # Laptop-specific sysctl overrides (if any)
  boot.kernel.sysctl = {
    # Less aggressive swapping for laptop
    "vm.swappiness" = lib.mkOverride 50 10;
    "vm.vfs_cache_pressure" = lib.mkOverride 50 50;
    # Laptop-specific scheduler tweaks
    "kernel.sched_autogroup" = 0;
    "kernel.sched_rr_timeslice_ms" = 4;
  };

  # Laptop-specific boot optimizations
  boot = {
    # Framework-specific kernel parameters
    kernelParams = [
      # Framework laptop optimizations
      "acpi_osi=Linux"
      "acpi_backlight=vendor"
      "i915.fastboot=1"
      "i915.enable_guc=2"
      "i915.enable_fbc=1"
      "i915.enable_psr=1"
      # Power management
      "intel_pstate=performance"
      "processor.max_cstate=1"
      "intel_idle.max_cstate=1"
    ];

    # Enable early KMS for faster graphics initialization
    kernelModules = [ "i915" ];
  };

  # Enable thermal management for laptop
  services.thermald.enable = true;

  # Laptop-specific packages (if not already in global)
  environment.systemPackages = with pkgs; [
    powertop
    mission-center
  ];
}
