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

  boot = {
    # Desktop-specific boot optimizations
    kernelParams = [
      "acpi_osi=Linux"
      "acpi_backlight=vendor"
    ];

    # Enable early KMS for faster graphics initialization (modern way)
    initrd.kernelModules = [ "amdgpu" ];

    # If you truly also have Intel iGPU on this machine, you can add:
    # initrd.kernelModules = [ "amdgpu" "i915" ];
    #
    # and re-add i915 kernelParams. But for your Ryzen 9950X box, i915 is noise.

    # Non-initrd modules you want later in boot (usually optional)
    kernelModules = [ "amdgpu" ];
  };

  # Graphics stack (Mesa + Vulkan + VA-API)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    # These are the right kinds of things to put here.
    # (Mesa itself is typically pulled in automatically, so you don't need `mesa` explicitly.)
    extraPackages = with pkgs; [
      libva
      libvdpau-va-gl
      libva-vdpau-driver
    ];

    extraPackages32 = [];
  };

  # IMPORTANT:
  # Avoid setting VK_ICD_FILENAMES globally. It can break Vulkan discovery in other apps,
  # and can interfere with 32-bit ICD selection.
  #
  # If you need to force the Vulkan ICD for Ollama specifically, do it in the ollama service:
  #
  # systemd.services.ollama.serviceConfig.Environment = [
  #   "VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json"
  #   "AMD_VULKAN_ICD=RADV"
  #   "HIP_VISIBLE_DEVICES=0"
  #   "ROCR_VISIBLE_DEVICES=0"
  # ];
  #
  # If you run Ollama via home-manager user service instead, do the equivalent there.

  environment.variables = {
    # It's okay to prefer RADV; keep this if you want.
    AMD_VULKAN_ICD = "RADV";

    # Don't globally disable CUDA; it's harmless but can break other tooling.
    # If you want to ensure Ollama doesn't try NVIDIA, scope it to the Ollama service.
    # CUDA_VISIBLE_DEVICES = "";
  };

  environment.systemPackages = with pkgs; [
    # Monitoring
    amdgpu_top
    radeontop

    # ROCm tooling (keep here, not in hardware.graphics.*)
    rocmPackages.rocm-smi
    rocmPackages.rocminfo

    # Useful for debugging Vulkan setup
    vulkan-tools

    # Desktop GPU tuning
    corectrl
    gamemode
  ];

  # GPU device access for non-root users (compute uses /dev/dri/renderD*)
  #
  # Prefer: users.users.administrator.extraGroups = [ "render" "video" ];
  # But leaving your existing pattern to keep this file self-contained.
  users.groups.render.members = [ "administrator" ];

  # Optional but commonly needed:
  # users.groups.video.members = [ "administrator" ];
}
