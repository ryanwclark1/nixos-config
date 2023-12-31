{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.dconf.enable = true;
  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
  ]) ++ (with pkgs.gnome; [
    cheese # webcam tool
    gnome-music
    gedit # text editor
    epiphany # web browser
    geary # email reader
    gnome-characters
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
    gnome.gnome-tweaks
    gnomeExtensions.appindicator
  ];

  # ensure gnome-settings-daemon udev rules are enabled
  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

  home-manager.users.administrator = {
    dconf = {
      enable = true;
      settings = {
        "org/gnome/desktop/interface".color-scheme = "prefer-dark";
        "org/gnome/desktop/wm/preferences".button-layout = "appmenu:minimize,maximize,close";
        "org/gnome/shell".favorite-apps = ['org.gnome.Nautilus.desktop', 'code.desktop', 'chromium-browser.desktop', 'org.kde.konsole.desktop'];
        "org/gnome/shell".disable-user-extensions = false;
      };
      # settings.enable-extensions = [
      #   "Vitals@CoreCoding.com"
      # ];
    };
  };

#  home-manager.users.administrator.home.packages = with pkgs; [
#    gnomeExtensions.vitals
#  ];


}