{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Hardware modules
    inputs.nixos-hardware.nixosModules.framework-12th-gen-intel

    # Host-specific files
    ./hardware-configuration.nix
    ./services
    ./performance.nix

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
    ../common/optional/system-packages.nix
    ../common/optional/thunar.nix
    ../common/optional/virtualisation.nix
    ../common/optional/webcam.nix
    ../common/optional/wireshark.nix
    ../common/optional/zsh.nix
    ../common/optional/gnome
    ../common/optional/displaymanager/gdm.nix
    ../common/optional/hyprland
  ];

  # Host-specific settings
  networking.hostName = "frametop";

  # Override boot settings for laptop
  boot = {
    # Disable tmp cleaning for laptop
    tmp.cleanOnBoot = false;

    # Enable binary format support
    binfmt.emulatedSystems = [ "aarch64-linux" "i686-linux" ];
  };

  # Framework-specific hardware settings
  hardware = {
    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
  };

  # Laptop-specific power management
  powerManagement = {
    powertop.enable = true;
    cpuFreqGovernor = "powersave";
  };

  # Framework-specific security settings
  security.pam.services.login.fprintAuth = lib.mkForce true;

  # Framework-specific packages
  environment.systemPackages = with pkgs; [
    fw-ectool  # EC-Tool adjusted for usage with framework embedded controller
  ];

  system.stateVersion = "24.11";
}
