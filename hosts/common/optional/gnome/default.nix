{
  pkgs,
  ...
}:


{

  programs.dconf.enable = true;

  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
      displayManager = {
        gdm = {
          enable = true;
          wayland = true;
        };
      };
      desktopManager = {
        gnome = {
          enable = true;
          # List of packages for which gsettings are overridden. list of paths
          extraGSettingsOverridePackages = [ ];
          # Additional gsettings overrides. strings concatenated with "\n"
          extraGSettingsOverrides = "";
        };
      };
    };
    gnome = {
      core-developer-tools.enable = false;
      games.enable = false;
      sushi.enable = true; # File previewer
      rygel.enable = false; # DLNA/UPnP server
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
