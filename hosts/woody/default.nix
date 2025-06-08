{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    # Hardware modules
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd

    # Host-specific files
    ./hardware-configuration.nix
    ./services

    # Common configurations
    ../common/global
    ../common/users/administrator

    # Optional features
    ../common/optional/audio.nix
    ../common/optional/bluetooth.nix
    ../common/optional/direnv.nix
    ../common/optional/docker.nix
    ../common/optional/fonts.nix
    ../common/optional/gnome-services.nix
    ../common/optional/nautilus.nix
    ../common/optional/nfs.nix
    ../common/optional/printing.nix
    ../common/optional/steam.nix
    ../common/optional/syncthing.nix
    ../common/optional/system-packages.nix
    ../common/optional/style.nix
    ../common/optional/thunar.nix
    ../common/optional/virtualisation.nix
    ../common/optional/webcam.nix
    ../common/optional/wireshark.nix
    ../common/optional/zsh.nix
    ../common/optional/hyprland
    ../common/optional/displaymanager/sddm
  ];

  # Host-specific settings
  networking.hostName = "woody";

  # Override boot settings for desktop
  boot = {
    # Override tmp settings for desktop
    tmp.cleanOnBoot = true;

    # Override loader settings for desktop
    loader.systemd-boot.configurationLimit = 20;
  };

  # AMD-specific hardware settings
  hardware = {
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

    graphics = {
      extraPackages = with pkgs; [
        mesa
      ];
      extraPackages32 = with pkgs; [
        driversi686Linux.mesa
      ];
    };

    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
  };

  # Desktop-specific power management
  powerManagement = {
    cpuFreqGovernor = "performance";
  };

  system.stateVersion = "24.05";
}
