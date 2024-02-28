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
    kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_6_7.override {
      argsOverride = rec {
        src = pkgs.fetchurl {
              url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
              sha256 = "e489ec0e1370d089b446d565aded7a698093d2b7c4122a18f21edb6ef93d37d3";
        };
        version = "6.7.6";
        modDirVersion = "6.7.6";
        };
    });

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
