# ./host/woody/default.nix
{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ../common
    ./avahi.nix
    ./bluetooth.nix
    ./desktop.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./ssh.nix
    ./user.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # avoid error
  hardware.pulseaudio.enable = false;

  # Bootloader
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  boot.kernelModules = [ "nfs" "nfs4" ];

  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    git
    nfs-utils
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  security.polkit.enable = true;

  services = {
    dbus.packages = [ pkgs.gcr ];
    geoclue2.enable = true;
    gnome.gnome-keyring.enable = true; # libsecret
    # udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
  };

  system.stateVersion = "23.11";
}

