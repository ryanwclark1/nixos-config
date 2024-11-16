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
    ../common/optional/audio.nix
    ../common/optional/bluetooth.nix
    ../common/optional/direnv.nix
    ../common/optional/docker.nix
    # ../common/optional/k3s.nix
    ../common/optional/nfs.nix
    ../common/optional/nautilus.nix
    ../common/optional/printing.nix
    ../common/optional/qemu.nix
    ../common/optional/steam.nix
    ../common/optional/style.nix
    ../common/optional/syncthing.nix
    ../common/optional/system-packages.nix
    ../common/optional/tailscale.nix
    ../common/optional/thunar.nix
    # ../common/optional/virt-viewer.nix
    ../common/optional/webcam.nix
    ../common/optional/wireshark.nix
    ../common/optional/wireguard.nix
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
        configurationLimit = 20;
        consoleMode = "keep";

      };
      efi.canTouchEfiVariables = true;
    };
    plymouth = {
        enable = true;
      };
    tmp = {
      cleanOnBoot = true;
    };
    # lanzaboote = {
    #   enable = true;
    #   pkiBundle = "/etc/secureboot";
    # };
    kernelPackages = pkgs.linuxKernel.packages.linux_6_11;
  };

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    amdgpu = {
      amdvlk = {
        enable = true;
        # package = pkgs.amdvlk;
        supportExperimental.enable = true;
        support32Bit = {
          enable = true;
          # package = pkgs.driversi686Linux.amdvlk;
        };
      };
      initrd.enable = true;
      opencl.enable = true;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
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

  system.stateVersion = "24.05";
}
