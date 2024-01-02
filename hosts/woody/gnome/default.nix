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
    atomix
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
    gnome.dconf-editor
    gnomeExtensions.appindicator
  ];

  # ensure gnome-settings-daemon udev rules are enabled
  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

  home-manager.users.administrator = {
    dconf = {
      enable = true;
      settings = {

        "org/gnome/shell" = {
          favorite-apps = [
            "org.gnome.Nautilus.desktop"
            "code.desktop"
            "chromium-browser.desktop"
            "alacritty.desktop"
            "org.kde.konsole.desktop"
          ];
          disable-user-extensions = false;
          enabled-extensions = [
            "vitals@corecoding.com"
          ];
        };
        "org/gnome/desktop/interface".color-scheme = "prefer-dark";
        "org/gnome/desktop/wm/preferences".button-layout = "appmenu:minimize,maximize,close";
      };
      # settings.enable-extensions = [
      #   "Vitals@CoreCoding.com"
      # ];
    };
    home.packages = with pkgs.gnomeExtensions; [
      vitals
      blur-my-shell
      gsconnect
    ];
  };

}