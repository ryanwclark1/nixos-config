{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.hardware.nixosModules.framework-12th-gen-intel
    ./hardware-configuration.nix
    ./services

    ../common/global
    ../common/users/administrator

    ../common/optional/bluetooth.nix
    ../common/optional/docker.nix
    ../common/optional/fail2ban.nix
    ../common/optional/nfs.nix
    ../common/optional/pipewire.nix
    ../common/optional/printing.nix
    ../common/optional/qemu.nix
    ../common/optional/steam.nix
    ../common/optional/systemd-boot.nix
    ../common/optional/wireshark.nix

    # ../common/optional/hyprland
    ../common/optional/lightdm.nix
    ../common/optional/plasma
  ];

  networking = {
    hostName = "frametop";
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_6_7;
    binfmt.emulatedSystems = [ "aarch64-linux" "i686-linux" ];
  };

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };

  };

  environment.systemPackages = with pkgs; [
    # EC-Tool adjusted for usage with framework embedded controller.
    fw-ectool
    wget
    gitMinimal
  ];


  system.stateVersion = "24.05";
}
