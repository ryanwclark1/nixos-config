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
  };

  # AMD GPU configuration
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
    # AMD GPU monitoring and control
    amdgpu_top
    radeontop
    rocmPackages.rocm-smi  # ROCm System Management Interface

    # Performance monitoring
    corectrl  # GUI for CPU/GPU control
    gamemode  # Game mode optimization
  ];
}
