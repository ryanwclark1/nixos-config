{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-12th-gen-intel
    ./hardware-configuration.nix
    ./services
    ../common/global
    ../common/users/administrator
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

  networking = {
    hostName = "frametop";
  };

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "keep";
      };
      efi.canTouchEfiVariables = true;
    };
    plymouth = {
      enable = true;
    };
    # tmp = {
    #   cleanOnBoot = true;
    # };
    kernelPackages = pkgs.linuxKernel.packages.linux_6_12;
    binfmt.emulatedSystems = [ "aarch64-linux" "i686-linux" ];
  };

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
  };

  powerManagement.powertop.enable = true;
  security.pam.services.login.fprintAuth = lib.mkForce true;
  environment.systemPackages = with pkgs; [
    fw-ectool  # EC-Tool adjusted for usage with framework embedded controller.
  ];

  system.stateVersion = "24.11";
}
