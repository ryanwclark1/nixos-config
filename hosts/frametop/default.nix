# ./host/frametop/default.nix
{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ../common
    ./bluetooth.nix
    ./desktop.nix
    ./hardware-configuration.nix
    ./networking.nix
    ./power-management.nix
    ./ssh.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.fwupd = {
    # bios updating tool
    enable = true;
  };

  services.thermald = {
    # Intel Thermal Management
    enable = true;
  };

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

  # Touchpad
  services.xserver.libinput = {
    enable = true;
    # tapping = true;
    # naturalScroll = true;
  };

  services = {
    dbus.packages = [ pkgs.gcr ];
    geoclue2.enable = true;
    gnome.gnome-keyring.enable = true; # libsecret
    # udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];
  };

  system.stateVersion = "23.11";
}

