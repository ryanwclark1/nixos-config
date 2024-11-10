{
  config,
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

    ../common/optional/bluetooth.nix
    ../common/optional/docker.nix
    ../common/optional/direnv.nix
    # ../common/optional/k3s.nix
    ../common/optional/nautilus.nix
    ../common/optional/nfs.nix
    ../common/optional/audio.nix
    ../common/optional/printing.nix
    ../common/optional/qemu.nix
    ../common/optional/steam.nix
    ../common/optional/style.nix
    ../common/optional/system-packages.nix
    ../common/optional/tailscale.nix
    ../common/optional/thunar.nix
    # ../common/optional/virt-viewer.nix
    ../common/optional/webcam.nix
    ../common/optional/wireshark.nix
    # ../common/optional/semaphore.nix
    ../common/optional/zsh.nix

    # ../common/optional/displaymanager/cosmic.nix
    # ../common/optional/cosmic
    ../common/optional/displaymanager/sddm
    ../common/optional/plasma
    ../common/optional/hyprland
  ];

  networking = {
    hostName = "frametop";
  };

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        # consoleMode = "keep";
      };
      efi.canTouchEfiVariables = true;
    };
    # kernelPackages = pkgs.linuxKernel.packages.linux_6_9;
    binfmt.emulatedSystems = [ "aarch64-linux" "i686-linux" ];
  };

  # Added for nixd lsp
  # nix.nixPath = [
  #   "nixpkgs=${inputs.nixpkgs.path}"
  # ];

  hardware = {
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
  security.pam.services.login.fprintAuth = true;
  environment.systemPackages = with pkgs; [
    fw-ectool  # EC-Tool adjusted for usage with framework embedded controller.
  ];

  system.stateVersion = "24.11";
}
