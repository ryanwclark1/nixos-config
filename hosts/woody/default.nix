{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./services

    ../common/global
    ../common/users/administrator

    ../common/optional/bluetooth.nix
    ../common/optional/docker.nix
    ../common/optional/fail2ban.nix
    ../common/optional/gamemode.nix
    # ../common/optional/k3s.nix
    ../common/optional/nfs.nix
    ../common/optional/pipewire.nix
    ../common/optional/printing.nix
    ../common/optional/qemu.nix
    ../common/optional/steam.nix
    ../common/optional/systemd-boot.nix
    ../common/optional/wireshark.nix

    ../common/optional/gnome
  ];

  networking = {
    hostName = "woody";
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    # kernelPackages = pkgs.linuxKernel.packages.linux_6_6;
    # initrd.kernelModules = [ "amdgpu" ];
    # binfmt.emulatedSystems = [ "aarch64-linux" "i686-linux" ];
  };

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      # extraPackages = with pkgs; [
      #   amdvlk
      # ];
      # extraPackages32 = with pkgs; [
      #   driversi686Linux.amdvlk
      # ];
    };

    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    wget
    git
  ];

  system.stateVersion = "24.05";
}
