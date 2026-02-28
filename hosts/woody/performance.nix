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
      # AMD GPU specific settings
      "amdgpu.si_support=1"
      "amdgpu.cik_support=1"
      "radeon.si_support=0"
      "radeon.cik_support=0"
      # Intel GPU optimizations (if present)
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
      enable32Bit = true; # 32-bit app support
      extraPackages = with pkgs; [
        # Mesa drivers
        mesa
        # AMD Vulkan drivers
        # amdvlk
        # driversi686Linux.amdvlk
        # ROCm packages for compute acceleration
        rocmPackages.clr
        rocmPackages.clr.icd
        rocmPackages.rocminfo # For ROCm device detection
        rocmPackages.rocm-smi # For monitoring and verification
        # Video acceleration
        libva
        libvdpau-va-gl
        libva-vdpau-driver
      ];
      extraPackages32 = with pkgs.driversi686Linux; [
        mesa
        # amdvlk
      ];
    };
    # amdgpu = {
    #   amdvlk = {
    #     enable = true;
    #     supportExperimental.enable = true;
    #     support32Bit = {
    #       enable = true;
    #     };
    #   };
    #   initrd.enable = true;
    #   opencl.enable = true;
    # };
  };

  # Environment variables for AMD graphics
  environment.variables = {
    # Force AMD GPU for applications
    AMD_VULKAN_ICD = "RADV";
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
    # Mesa configuration for better compatibility
    MESA_LOADER_DRIVER_OVERRIDE = "radeonsi";
    # ROCm environment variables for compute acceleration
    # Ensure ROCm is detected and used instead of CUDA
    # HSA_OVERRIDE_GFX_VERSION may be needed for some GPUs - uncomment and adjust if ROCm isn't detected
    # Common values: "10.3.0" (RDNA/RDNA2), "11.0.0" (RDNA3), "9.0.0" (Vega)
    # Check your GPU architecture with: rocminfo | grep -i "marketing"
    # ROCM_PATH = "${pkgs.rocmPackages.clr}";
    # Disable CUDA to prevent fallback to CUDA (which causes the max_blocks_per_sm error)
    CUDA_VISIBLE_DEVICES = "";
  };

  # Desktop-specific packages
  environment.systemPackages = with pkgs; [
    amdgpu_top
    radeontop
    rocmPackages.rocm-smi
    rocmPackages.rocminfo # For verifying ROCm installation
    corectrl
    gamemode
  ];

  # Ensure render group has access to GPU devices for ROCm
  # This is critical for Ollama (running via home-manager as administrator) to access the GPU
  # The render group provides access to /dev/dri/renderD* devices needed for compute
  users.groups.render.members = [ "administrator" ];
}
