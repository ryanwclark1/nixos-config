{
  pkgs,
  lib,
  ...
}:


{
  programs.dconf.enable = lib.mkDefault true;
  services = {
    xserver = {
      desktopManager = {
        gnome = {
          enable = lib.mkDefault true;
        };
      };
    };
    gnome = {
      at-spi2-core.enable = lib.mkDefault false; # Assistive Technologies available on the GNOME platform
      core-developer-tools.enable = lib.mkDefault false;
      core-os-services.enable = lib.mkDefault true;
      core-shell.enable = lib.mkDefault true;
      core-utilities.enable = lib.mkDefault true;
      evolution-data-server = {
        enable = lib.mkDefault false; #collection of services for storing addressbooks and calendars
        # plugins = [];
      };
      games.enable = lib.mkDefault false;
      glib-networking.enable = lib.mkDefault true;
      gnome-browser-connector.enable = lib.mkDefault true; # DBus service allowing to install GNOME Shell extensions from a web browser
      gnome-initial-setup.enable = lib.mkForce false; # First time setup wizard
      gnome-keyring.enable = lib.mkDefault true;
      gnome-online-accounts.enable = lib.mkDefault true; # service that provides a single sign-on framework
      gnome-online-miners.enable = lib.mkDefault false; # service that crawls through your online content
      gnome-remote-desktop.enable = lib.mkDefault true;
      gnome-settings-daemon.enable = lib.mkDefault true;
      gnome-user-share.enable = lib.mkDefault true; # user-level file sharing service for GNOME
      rygel.enable = lib.mkDefault true; # DLNA/UPnP server
      sushi.enable = lib.mkDefault true; # File previewer
      tracker.enable = lib.mkDefault true; # Tracker search engine and metadata storage
      tracker-miners.enable = lib.mkDefault true; # indexing services for Tracker search engine and metadata storage
    };
  };

  environment.sessionVariables ={
    NIXOS_OZONE_WL = "1";
  };

  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
  ]) ++ (with pkgs.gnome; [
    cheese # webcam tool
    gnome-music
    epiphany # web browser
    geary # email reader
    yelp # Help view
    gnome-contacts
  ]);

  environment.systemPackages = (with pkgs; [
    gnomeExtensions.appindicator
  ]) ++ (with pkgs.gnome; [
    adwaita-icon-theme
    dconf-editor
    gnome-boxes
    gnome-control-center
    gnome-nettool
    gnome-tweaks
    gnome-bluetooth
    vinagre
  ]);

  # ensure gnome-settings-daemon udev rules are enabled
  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

  # This is enabled if service.gnome.keyring.enable is true
  # security.pam.services.login.enableGnomeKeyring = true;
}
