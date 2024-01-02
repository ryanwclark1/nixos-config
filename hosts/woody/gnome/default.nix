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
            "Vitals@CoreCoding.com"
            "blur-my-shell@aunetx"
            "gsconnect@andyholmes.github.io"
            "dash-to-panel@jderose9.github.com"
            "BingWallpaper@ineffable-gmail.com"
          ];
        };
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          enable-hot-corners = false;
          clock-show-weekday = true;
        };
        "org/gnome/desktop/privacy" = {
          report-technical-problems = "false";
        };
        "org/gnome/desktop/calendar" = {
          show-weekdate = true;
        };
        "org/gnome/desktop/wm/preferences" = {
          action-right-click-titlebar = "toggle-maximize";
          action-middle-click-titlebar = "minimize";
          resize-with-right-button = true;
          mouse-button-modifier = "<super>";
          button-layout = "appmenu:minimize,maximize,close";
        };
        "org/gnome/shell/extensions/dash-to-panel" = {
          intellihide = true;
          panel-positions = ''{"0":"BOTTOM"}'';
          panel-sizes = ''{"0":55}'';
          panel-lengths = ''{"0":40}'';
          panel-anchors = ''{"0":"MIDDLE"}'';
          panel-element-positions = ''{"0":[{"element":"showAppsButton","visible":true,"position":"stackedTL"},{"element":"activitiesButton","visible":true,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":false,"position":"stackedBR"},{"element":"systemMenu","visible":false,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}'';
          showdesktop-button-width = 10;
          animate-appicon-hover = true;
          dot-style-focused = "DOTS";
          dot-style-unfocused = "DOTS";
          trans-use-custom-bg = true;
          trans-use-custom-opacity = true;
          trans-use-dynamic-opacity = true;
          show-favorites = true;
          show-favorites-all-monitors = false;
          progress-show-count = true;
          show-window-previews = true;
          show-tooltip = true;
          animate-app-switch = true;
          animate-window-launch = true;
          stockgs-keep-dash = true;
          stockgs-keep-top-panel = true;
          stockgs-panelbtn-click-only = true;
          stockgs-force-hotcorner = true;
          secondarymenu-contains-appmenu = true;
        };

      };
    };
    home.packages = with pkgs.gnomeExtensions; [
      vitals
      blur-my-shell
      gsconnect
      dash-to-panel
      bing-wallpaper-changer
    ];
  };

}