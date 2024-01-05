{ pkgs, ... }:

{
  # AMDGPU configuration
  # Move this to xserver or test that xserver is enabled
  services.xserver.videoDrivers = [ "amdgpu" ];

  boot.initrd.kernelModules = [ "amdgpu" ];


  # You should also install the clinfo package
  # to verify that OpenCL is correctly setup check darktable
  hardware.opengl.extraPackages = with pkgs; [
    rocmPackages.clr.icd
    rocm-opencl-runtime
    amdvlk
  ];

  # problems having multiple monitors connected to your GPU,
  # adding `video` parameters for each connector to the kernel command line sometimes helps.
  # To figure out the connector names head /sys/class/drm/*/status
  # boot.kernelParams = [
  #   "video=DP-1:2560x1440@144"
  #   "video=DP-2:2560x1440@144"
  # ];

  # For 32 bit applications
  hardware.opengl.extraPackages32 = with pkgs; [
    driversi686Linux.amdvlk
  ];

  # Vulkan is already enabled by default (using Mesa RADV) on 64 bit applications
  # Settings to control
  hardware.opengl.driSupport = true; # This is already enabled by default
  hardware.opengl.driSupport32Bit = true; # For 32 bit applications


  # hardware.opengl.extraPackages = with pkgs; [
  #   amdvlk
  # ];
}
