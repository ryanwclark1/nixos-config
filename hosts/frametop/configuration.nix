# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, system, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./main-user.nix
      ./networking.nix
      ./power-management.nix
      ./ssh.nix
      ../common/nfs.nix
      ../common/locale.nix
      ../common/printing.nix
      ../common/bootloader.nix
      ../common/audio.nix
      ../common/docker.nix
      ../common/qemu.nix
      ../common/fonts.nix
      ../common/transmission.nix

      ../common/plasma
      ../common/hyprland
    ];
  nfs.enable = true;
  printing.enable = true;
  audio.enable = true;
  docker.enable = true;
  transmission.enable = false;

  plasma.enable = false;
  hyprland.enable = true;


  main-user.enable = true;
  main-user.userName = "administrator";

  networking.hostName = "frametop"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable Wayland support
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  services = {
    # bios updating tool
    fwupd.enable = true;
    # Intel Thermal Management
    thermald.enable = true;
    # Automatic CPU speed & power optimizer for Linux
    # Runs well with thermald
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
  };

  services.vscode-server.enable = true;

  # nixpkgs.config.packageOverrides = pkgs: {
  #   vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  # };
  # hardware.opengl = {
  #   enable = true;
  #   extraPackages = with pkgs; [
  #     intel-media-driver # LIBVA_DRIVER_NAME=iHD
  #     vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
  #     vaapiVdpau
  #     libvdpau-va-gl
  #   ];
  #   extraPackages32 = with pkgs.pkgsi686Linux; [ vaapiIntel ];
  # };


  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput = {
    enable = true;
    # tapping = true;
    # naturalScroll = true;
  };

  # Mouse enabled
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;



  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
      inherit system;
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

####  Previously Included  #####
  # security.polkit.enable = true;
  # services = {
  #   dbus.packages = [ pkgs.gcr ];
  #   geoclue2.enable = true;
  #   gnome.gnome-keyring.enable = true; # libsecret
  #   # udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
  # };
#################################

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
