{
  inputs,
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
    # ../common/optional/k3s.nix
    ../common/optional/nfs.nix
    ../common/optional/pipewire.nix
    ../common/optional/printing.nix
    ../common/optional/qemu.nix
    ../common/optional/steam.nix
    ../common/optional/tailscale.nix
    ../common/optional/theme.nix
    ../common/optional/wireshark.nix
    # ../common/optional/semaphore.nix


    ../common/optional/displaymanager/cosmic.nix
    ../common/optional/cosmic
    # ../common/optional/displaymanager/sddm/
    # ../common/optional/plasma
    # ../common/optional/hyprland
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
    kernelPackages = pkgs.linuxKernel.packages.linux_6_9;
    binfmt.emulatedSystems = [ "aarch64-linux" "i686-linux" ];
  };

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

  environment.systemPackages = with pkgs; [
    fw-ectool  # EC-Tool adjusted for usage with framework embedded controller.
    wget
    gitMinimal
  ];

  system.stateVersion = "24.05";
}
