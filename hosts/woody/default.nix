{ pkgs, inputs, ... }: {
  imports = [
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    ./hardware-configuration.nix
  ];

networking = {
    hostName = "woody";
    useDHCP = true;
    firewall.enable = false;
    nameservers = [
      "10.10.100.1"
      "9.9.9.9"
      "1.1.1.1"
    ];
    wireguard.enable = true;
  };

  # boot = {
  #   kernelPackages = pkgs.linuxKernel.packages.linux_zen;
  #   binfmt.emulatedSystems = [ "aarch64-linux" "i686-linux" ];
  # };

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi = {
        canTouchEfiVariables = true;
      };
      timeout = 1;
    };
  };

  programs = {
    adb.enable = true;
    dconf.enable = true;
    kdeconnect.enable = true;
  };

  services.hardware.openrgb.enable = true;

  hardware ={
    opengl = {
      enable = true;
      driSupport = true; # This is already enabled by default
      driSupport32Bit = true; # For 32 bit applications
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
        rocm-opencl-runtime
        amdvlk
        libva-utils
      ];
      extraPackages32 = with pkgs; [
        driversi686Linux.amdvlk
      ];
    };
    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
  };

  system.stateVersion = "23.11";
}