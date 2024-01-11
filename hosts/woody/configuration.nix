# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, system, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./gpu.nix
      ./main-user.nix
      ./networking.nix
      ./ssh.nix
      ../common/gnome
      ../common/nfs.nix
      ../common/locale.nix
      ../common/printing.nix
      ../common/bootloader.nix
      ../common/audio.nix
      ../common/docker.nix
      ../common/qemu.nix
      ../common/fonts.nix
      ../common/transmission.nix
    ];
  nfs.enable = true;
  gnome.enable = true;
  printing.enable = true;
  audio.enable = true;
  docker.enable = true;
  transmission.enable = false;
  qemu.enable = true;

  main-user.enable = true;
  main-user.userName = "administrator";

  # Enable Wayland support
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  services = {
    # bios updating tool
    fwupd.enable = true;
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

  networking.hostName = "woody"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

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
  ];

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
