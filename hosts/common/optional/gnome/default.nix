{
  pkgs,
  lib,
  ...
}:


{

  programs.dconf.enable = true;
  services = {
    xserver = {
      desktopManager = {
        gnome = {
          enable = true;
        };
      };
    };
    gnome = {
      at-spi2-core.enable = false; # Assistive Technologies available on the GNOME platform
      core-developer-tools.enable = false;
      core-os-services.enable = true;
      core-shell.enable = true;
      core-utilities.enable = true;
      evolution-data-server = {
        enable = false; #collection of services for storing addressbooks and calendars
        # plugins = [];
      };
      games.enable = false;
      glib-networking.enable = true;
      gnome-browser-connector.enable = false; # DBus service allowing to install GNOME Shell extensions from a web browser
      gnome-initial-setup.enable = false; # First time setup wizard
      gnome-keyring.enable = true;
      gnome-online-accounts.enable = true; # service that provides a single sign-on framework
      gnome-online-miners.enable = false; # service that crawls through your online content
      gnome-remote-desktop = true;
      gnome-settings-daemon.enable = true;
      gnome-user-share.enable = true; # user-level file sharing service for GNOME
      rygel.enable = false; # DLNA/UPnP server
      sushi.enable = true; # File previewer
      tracker.enable = true; # Tracker search engine and metadata storage
      tracker-miners.enable = true; # indexing services for Tracker search engine and metadata storage
    };
  };

  environment.sessionVariables ={
    NIXOS_OZONE_WL = "1";
  };

  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    gedit
  ]) ++ (with pkgs.gnome; [
    cheese # webcam tool
    gnome-music
    epiphany # web browser
    geary # email reader
    tali # poker game
    iagno # go game
    hitori # sudoku game
    atomix # puzzle game
    yelp # Help view
    gnome-contacts
    gnome-initial-setup
  ]);

  environment.systemPackages = with pkgs; [
    gnome.adwaita-icon-theme
    gnome.gnome-nettool
    gnome.gnome-tweaks
    gnome.dconf-editor
    gnome.gnome-boxes
    gnomeExtensions.appindicator
  ];

  # ensure gnome-settings-daemon udev rules are enabled
  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

  security.pam.services.login.enableGnomeKeyring = true;
}
