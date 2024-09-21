{
  pkgs,
  lib,
  config,
  ...
}: {
  options.gnome = {
    enable = lib.mkEnableOption "Gnome";
  };

  config = lib.mkIf config.gnome.enable {
    environment = {
      systemPackages = with pkgs; [
        morewaita-icon-theme
        qogir-icon-theme
        gnome-extension-manager
        wl-clipboard
      ];

      gnome.excludePackages =
        (with pkgs; [
          # gnome-text-editor
          gnome-console
          gnome-photos
          gnome-tour
          gnome-connections
          snapshot
          gedit
          cheese # webcam tool
          epiphany # web browser
          geary # email reader
          evince # document viewer
          totem # video player
          yelp # Help view
          gnome-font-viewer
        ])
        ++ (with pkgs.gnome; [
          gnome-music
          gnome-characters
          tali # poker game
          iagno # go game
          hitori # sudoku game
          atomix # puzzle game
          gnome-contacts
          gnome-initial-setup
          gnome-shell-extensions
          gnome-maps
        ]);
    };

    services.xserver = {
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    programs.dconf.profiles.gdm.databases = [
      {
        settings = {
          "org/gnome/desktop/peripherals/touchpad" = {
            tap-to-click = true;
          };
          "org/gnome/desktop/interface" = {
            cursor-theme = "Qogir";
          };
        };
      }
    ];
  };
}



# gnomeExtensions.appindicator
#         adwaita-icon-theme
#         dconf-editor
#         gnome-tweaks
#         gnome-boxes
#         gnome-control-center
#         gnome-nettool
#         gnome-bluetooth

  # services.udev.packages = with pkgs; [ gnome-settings-daemon ];

    # gnome = {
      # at-spi2-core.enable = lib.mkDefault false; # Assistive Technologies available on the GNOME platform
      # core-developer-tools.enable = lib.mkDefault false;
      # core-os-services.enable = lib.mkDefault true;
      # core-shell.enable = lib.mkDefault true;
      # core-utilities.enable = lib.mkDefault true;
      # evolution-data-server = {
      #   enable = lib.mkDefault false; #collection of services for storing addressbooks and calendars
      #   # plugins = [];
      # };
      # games.enable = lib.mkDefault false;
      # glib-networking.enable = lib.mkDefault true;
      # gnome-browser-connector.enable = lib.mkDefault true; # DBus service allowing to install GNOME Shell extensions from a web browser
      # gnome-initial-setup.enable = lib.mkForce false; # First time setup wizard
      # gnome-keyring.enable = lib.mkDefault true;
      # gnome-online-accounts.enable = lib.mkDefault true; # service that provides a single sign-on framework
      # # gnome-online-miners.enable = lib.mkDefault false; # service that crawls through your online content
      # gnome-remote-desktop.enable = lib.mkDefault true;
      # gnome-settings-daemon.enable = lib.mkDefault true;
      # gnome-user-share.enable = lib.mkDefault true; # user-level file sharing service for GNOME
      # rygel.enable = lib.mkDefault true; # DLNA/UPnP server
      # sushi.enable = lib.mkDefault true; # File previewer
      # tracker.enable = lib.mkDefault true; # Tracker search engine and metadata storage
      # tracker-miners.enable = lib.mkDefault true; # indexing services for Tracker search engine and metadata storage
    # };