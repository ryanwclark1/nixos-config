# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./networking.nix
      ./power-management.nix
      ./ssh.nix
      ../common/main-user.nix
      ../common/plasma
      ../common/nfs.nix
      ../common/locale.nix
      ../common/printing.nix
      ../common/audio.nix
      ../common/docker.nix
      ../common/qemu.nix
      ../common/fonts.nix
      ../common/transmission.nix
      ../common/steam.nix
      inputs.hardware.nixosModules.framework-12th-gen-intel
      inputs.hardware.nixosModules.common-pc-ssd
    ];
  nfs.enable = true;
  printing.enable = true;
  audio.enable = true;
  docker.enable = true;
  transmission.enable = false;
  steam.enable = true;

  plasma.enable = true;

  main-user.enable = true;
  main-user.userName = "administrator";

  networking = {
    hostName = "frametop"; # Define your hostname.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    networkmanager.enable = true;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable Wayland support
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  services = {
    fwupd.enable = true; # bios updating tool
    thermald.enable = true; # Intel Thermal Management
    # Automatic CPU speed & power optimizer runs well with thermald
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
           governor = "powersave";
           turbo = "never";
        };
        charger = {
           governor = "performance";
           turbo = "auto";
        };
      };
    };
    tailscale = {
      enable = true;
      package = pkgs.tailscale;
      extraUpFlags = [];
      authKeyFile = null;
      interfaceName = "tailscale0";
      permitCertUid = null;
      port = 41641;
      useRoutingFeatures = "none";
    };
    vscode-server.enable = true;
    # touchpad support (enabled default in most desktopManager).
    xserver.libinput = {
      enable = true;
      # tapping = true;
      # naturalScroll = true;
    };
  };

  # Mouse enabled
  hardware = {
    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
    };

    users = {
      "administrator" = import ./home.nix;
    };

  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    curl
    git
    nfs-utils # Enable base on nfs
    # EC-Tool adjusted for usage with framework embedded controller.
    fw-ectool
  ];

  system.stateVersion = "23.11"; # Change carefully

}
