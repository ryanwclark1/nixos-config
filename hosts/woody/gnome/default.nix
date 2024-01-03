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
            "code.desktop"
            "alacritty.desktop"
            "chromium-browser.desktop"
            "firefox.desktop"
            "org.gnome.Nautilus.desktop"
          ];
          disable-user-extensions = false;
          enabled-extensions = [
            "Vitals@CoreCoding.com"
            "BingWallpaper@ineffable-gmail.com"
            "trayiconsreloaded@selfmade.pl"
            "blur-my-shell@aunetx"
            "drive-menu@gnome-shell-extensions.gcampax.github.com"
            "dash-to-panel@jderose9.github.com"
            "just-perfection-desktop@just-perfection"
            "caffeine@patapon.info"
            "clipboard-indicator@tudmotu.com"
            "horizontal-workspace-indicator@tty2.io"
            "bluetooth-quick-connect@bjarosze.gmail.com"
            "gsconnect@andyholmes.github.io"
            "pip-on-top@rafostar.github.com"
            "forge@jmmaranan.com"
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
        "org/gnome/desktop/wm/keybindings" = {
          # maximize = ["<super>up"];                   # Floating
          # unmaximize = ["<super>down"];
          maximize = ["@as []"];                        # Tiling
          unmaximize = ["@as []"];
          switch-to-workspace-left = ["<alt>left"];
          switch-to-workspace-right = ["<alt>right"];
          switch-to-workspace-1 = ["<alt>1"];
          switch-to-workspace-2 = ["<alt>2"];
          switch-to-workspace-3 = ["<alt>3"];
          switch-to-workspace-4 = ["<alt>4"];
          switch-to-workspace-5 = ["<alt>5"];
          move-to-workspace-left = ["<shift><alt>left"];
          move-to-workspace-right = ["<shift><alt>right"];
          move-to-workspace-1 = ["<shift><alt>1"];
          move-to-workspace-2 = ["<shift><alt>2"];
          move-to-workspace-3 = ["<shift><alt>3"];
          move-to-workspace-4 = ["<shift><alt>4"];
          move-to-workspace-5 = ["<shift><alt>5"];
          move-to-monitor-left = ["<super><alt>left"];
          move-to-monitor-right = ["<super><alt>right"];
          close = ["<super>q" "<alt>f4"];
          toggle-fullscreen = ["<super>f"];
        };
        "org/gnome/mutter" = {
          workspaces-only-on-primary = false;
          center-new-windows = true;
          edge-tiling = false;                          # Tiling
        };
        "org/gnome/mutter/keybindings" = {
          #toggle-tiled-left = ["<super>left"];         # Floating
          #toggle-tiled-right = ["<super>right"];
          toggle-tiled-left = ["@as []"];               # Tiling
          toggle-tiled-right = ["@as []"];
        };
        "org/gnome/settings-daemon/plugins/media-keys" = {
          custom-keybindings = [
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
          ];
        };
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          binding = "<super>return";
          command = "alacritty";
          name = "open-terminal";
        };
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
          binding = "<super>t";
          command = "code";
          name = "open-editor";
        };
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
          binding = "<super>e";
          command = "nautilus";
          name = "open-file-browser";
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
        "org/gnome/shell/extensions/just-perfection" = {
          theme = true;
          activities-button = false;
          app-menu = false;
          clock-menu-position = 1;
          clock-menu-position-offset = 7;
        };
        "org/gnome/shell/extensions/caffeine" = {
          enable-fullscreen = true;
          restore-state = true;
          show-indicator = true;
          show-notification = false;
        };
        "org/gnome/shell/extensions/blur-my-shell" = {
          brightness = 0.9;
        };
        "org/gnome/shell/extensions/blur-my-shell/panel" = {
          customize = true;
          sigma = 0;
        };
        "org/gnome/shell/extensions/blur-my-shell/overview" = {
          customize = true;
          sigma = 0;
        };
        "org/gnome/shell/extensions/horizontal-workspace-indicator" = {
          widget-position = "left";
          widget-orientation = "horizontal";
          icons-style = "circles";
        };
        "org/gnome/shell/extensions/bluetooth-quick-connect" = {
          show-battery-icon-on = true;
          show-battery-value-on = true;
        };
        "org/gnome/shell/extensions/pip-on-top" = {
          stick = true;
        };
        "org/gnome/shell/extensions/forge" = {
          window-gap-size = 8;
          dnd-center-layout = "stacked";
        };
        "org/gnome/shell/extensions/forge/keybindings" = { # Set Manually
          focus-border-toggle = true;
          float-always-on-top-enabled = true;
          window-focus-up = ["<super>up"];
          window-focus-down = ["<super>down"];
          window-focus-left = ["<super>left"];
          window-focus-right = ["<super>right"];
          window-move-up = ["<shift><super>up"];
          window-move-down = ["<shift><super>down"];
          window-move-left = ["<shift><super>left"];
          window-move-right = ["<shift><super>right"];
          window-swap-last-active = ["@as []"];
          window-toggle-float = ["<shift><super>f"];
        };
        "org/gtk/gtk4/settings/file-chooser".sort-directories-first = true;
      };
    };
    home.packages = with pkgs.gnomeExtensions; [
      vitals
      bing-wallpaper-changer
      tray-icons-reloaded
      blur-my-shell
      removable-drive-menu
      dash-to-panel
      just-perfection
      caffeine
      clipboard-indicator
      workspace-indicator-2
      bluetooth-quick-connect
      gsconnect
      pip-on-top
      pop-shell
      forge
    ];
  };

}