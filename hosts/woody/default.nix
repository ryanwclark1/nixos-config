{
  inputs,
  pkgs,
  lib,
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
    ../common/optional/syncthing.nix
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

    # Override kernel to use zen kernel for better desktop performance
    # Zen kernel provides better latency and responsiveness for desktop workloads
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;

    # Override loader settings for desktop
    # Keep more boot entries for desktop (20 vs global default of 10)
    # - Desktop systems often need more entries for development/testing
    # - Allows for more experimentation with configurations
    # - Provides extended rollback capability for complex setups
    # - Desktop typically has more disk space available
    loader.systemd-boot.configurationLimit = lib.mkForce 20;
  };

  # Desktop-specific power management
  powerManagement = {
    cpuFreqGovernor = "performance";
  };

  system.stateVersion = "24.05";
}
