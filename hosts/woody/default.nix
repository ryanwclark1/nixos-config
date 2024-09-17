{
  inputs,
  pkgs,
  ...
}:

{
  imports = [

    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ./hardware-configuration.nix
    ./services

    ../common/global
    ../common/users/administrator

    # ../common/optional/arion.nix
    ../common/optional/bluetooth.nix
    ../common/optional/direnv.nix
    ../common/optional/docker.nix
    # ../common/optional/k3s.nix
    ../common/optional/nfs.nix
    ../common/optional/pipewire.nix
    ../common/optional/printing.nix
    ../common/optional/qemu.nix
    ../common/optional/steam.nix
    ../common/optional/style.nix
    ../common/optional/syncthing.nix
    ../common/optional/system-packages.nix
    ../common/optional/tailscale.nix
    ../common/optional/thunar.nix
    ../common/optional/wireshark.nix
    ../common/optional/zsh.nix

    ../common/optional/displaymanager/gdm.nix
    ../common/optional/gnome
    ../common/optional/hyprland
  ];

  networking = {
    hostName = "woody";
  };

  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "keep";
      };
      efi.canTouchEfiVariables = true;
    };
    # lanzaboote = {
    #   enable = true;
    #   pkiBundle = "/etc/secureboot";
    # };
    kernelPackages = pkgs.linuxKernel.packages.linux_6_10;
  };

  hardware = {
    enableAllFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    cpu.amd = {
      updateMicrocode = true;
    };

    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    libGL
  ];

  system.stateVersion = "24.05";
}
