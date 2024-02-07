{
  config,
  pkgs,
  lib,
  ...
}:


{

  services = {
    xserver = {
      enable = true;
      layout = "us";
      displayManager = {
        gdm = {
          enable = true;
          # Would likely create issue if used on laptop.
          autoSuspend = false;
          wayland = true;
        };
      };
      desktopManager = {
        gnome = {
          enable = true;
          # List of packages for which gsettings are overridden. list of paths
          extraGSettingsOverridePackages = [];
          # Additional gsettings overrides. strings concatenated with "\n"
          extraGSettingsOverrides = "";
        };
      };
    };
    gnome = {
      games.enable = false;
      sushi.enable = true;
    };
    geoclue2.enable = true;
  };

  programs.dconf.enable = true;

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
    gnome.devhelp
    gnome.gnome-nettool
    gnome.gnome-tweaks
    gnome.dconf-editor
    gnome.gnome-boxes
    gnomeExtensions.appindicator
  ];

  # ensure gnome-settings-daemon udev rules are enabled
  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

  # Temp, find better place.  Allows for copy/paste between host and guest.
  services.spice-vdagentd.enable = true;

}