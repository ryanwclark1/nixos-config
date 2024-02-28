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
    kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_6_6.override {
      argsOverride = rec {
        src = pkgs.fetchurl {
              url = "mirror://kernel/linux/kernel/v6.x/linux-${version}.tar.xz";
              sha256 = "4e43d8c5fba14f7c82597838011648056487b7550fd83276ad534559e8499b1d";
        };
        version = "6.6.18";
        modDirVersion = "6.6.18";
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
    # UEFI boot manager
    refind
  ];

  system.stateVersion = "24.05";
}
