{
  lib,
  pkgs,
  ...
}:

{
  # Desktop-specific sysctl overrides
  boot.kernel.sysctl = {
    # More aggressive swapping for desktop
    "vm.swappiness" = lib.mkOverride 50 60;
    "vm.vfs_cache_pressure" = lib.mkOverride 50 100;
    # Desktop-specific scheduler tweaks
    "kernel.sched_autogroup" = 1;
    "kernel.sched_rr_timeslice_ms" = 1;
  };

  # Desktop-specific boot optimizations
  boot = {
    # Faster boot for desktop
    kernelParams = [
      # Desktop-specific optimizations
      "acpi_osi=Linux"
      "acpi_backlight=vendor"
      "i915.fastboot=1"
      "i915.enable_guc=2"
      "i915.enable_fbc=1"
      "i915.enable_psr=1"
    ];

    # Enable early KMS for faster graphics initialization
    kernelModules = [
      "i915"
      "amdgpu"
    ];
  };

  # AMD GPU configuration (desktop-specific)
  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        mesa
        rocmPackages.clr
        rocmPackages.clr.icd
      ];
      extraPackages32 = with pkgs; [
        driversi686Linux.mesa
      ];
    };
    amdgpu = {
      amdvlk = {
        enable = true;
        supportExperimental.enable = true;
        support32Bit = {
          enable = true;
        };
      };
      initrd.enable = true;
      opencl.enable = true;
    };
  };

  # Desktop-specific packages
  environment.systemPackages = with pkgs; [
    amdgpu_top
    radeontop
    rocmPackages.rocm-smi
    corectrl
    gamemode
  ];
}
