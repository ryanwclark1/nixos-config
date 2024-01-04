{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.dconf.enable = true;
  programs.kdeconnect.enable = true;

  environment.systemPackages = with pkgs; [       # Packages installed
    xorg.xkill
    (ark.override {unfreeEnableUnrar = true;})
    gwenview
    # kate
    # neovim-qt
    plasma5Packages.kdeconnect-kde

    keepassxc
    kget
    kgpg
    krename
    hunspell
    hunspellDicts.ru-ru
    hyphen
    okular
    qalculate-gtk

    kdeplasma-addons
    spectacle

    # Required by KInfoCenter
    clinfo # clinfo
    glxinfo # eglinfo, glxinfo
    pciutils # lspci
    vulkan-tools # vulkaninfo
    wayland-utils # wayland-info

    # Required by Nix
    gitMinimal

    plasma5Packages.dolphin-plugins
    plasma5Packages.ffmpegthumbs
    plasma5Packages.kdegraphics-thumbnailers
    plasma5Packages.kglobalaccel
    plasma5Packages.kio
    plasma5Packages.kio-extras

    libsForQt5.applet-window-buttons
    libsForQt5.discover
    libsForQt5.dolphin-plugins
    libsForQt5.kaccounts-integration
    libsForQt5.kaccounts-providers
    libsForQt5.kio
    libsForQt5.kio-gdrive
    libsForQt5.plasma-browser-integration
    libsForQt5.plasma-integration
    libsForQt5.qtstyleplugin-kvantum
    libsForQt5.bismuth
    lightly-qt

    # KDE/Plasma: support spellchecking
    hunspell
    hunspellDicts.en_US
    aspell
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science

    capitaine-cursors
    la-capitaine-icon-theme

    # Office
    # libreoffice-qt

    # Settings
    kgamma5

    filelight
    kcalc
#   kgpg
#   qttools
#   quazip
  ];

  environment.plasma5.excludePackages = with pkgs.libsForQt5; [
    elisa
    oxygen
  ];

  environment.etc = {
    "chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json".source = "${pkgs.plasma-browser-integration}/etc/chromium/native-messaging-hosts/org.kde.plasma.browser_integration.json";
  };

  environment.variables = {
    "QT_PLUGIN_PATH" = [ "/run/current-system/sw/"
                         "${pkgs.qt5.qtbase}/${pkgs.qt5.qtbase.qtPluginPrefix}:${pkgs.qt5.qtimageformats}/${pkgs.qt5.qtbase.qtPluginPrefix}" ];
    "QT_STYLE_OVERRIDE" = "kvantum";
  };

  home.packages = [ pkgs.plasmaPackages.bismuth ];

  programs.plasma.files.kwinrc = {
    files.kwinrc = {
      Plugins.bismuthEnabled = true;

      Script-bismuth = {
        ignoreClass = "yakuake,spectacle,Conky,zoom,plasma.emojier";
        screenGapBottom = 4;
        screenGapLeft = 4;
        screenGapRight = 4;
        screenGapTop = 4;
        tileLayoutGap = 4;
      };
    };
  };

  programs.plasma.shortcuts.bismuth = {
    decrease_master_size = [];
    decrease_master_win_count = [ "Meta+[" "Meta+D" ];
    decrease_window_height = "Meta+Ctrl+K";
    decrease_window_width = "Meta+Ctrl+H";
    focus_bottom_window = "Meta+J";
    focus_left_window = "Meta+H";
    focus_next_window = [];
    focus_prev_window = [];
    focus_right_window = "Meta+L";
    focus_upper_window = "Meta+K";
    increase_master_size = [];
    increase_master_win_count = [ "Meta+I" "Meta+]" ];
    increase_window_height = "Meta+Ctrl+J";
    increase_window_width = "Meta+Ctrl+L";
    move_window_to_bottom_pos = "Meta+Shift+J";
    move_window_to_left_pos = "Meta+Shift+H";
    move_window_to_next_pos = [];
    move_window_to_prev_pos = [];
    move_window_to_right_pos = "Meta+Shift+L";
    move_window_to_upper_pos = "Meta+Shift+K";
    next_layout = "Meta+\\,Meta+\\,Switch to the Next Layout";
    prev_layout = "Meta+|";
    push_window_to_master = "Meta+Return";
    rotate = "Meta+R";
    rotate_part = "Meta+Shift+R";
    rotate_reverse = [];
    toggle_float_layout = "Meta+Shift+F";
    toggle_monocle_layout = "Meta+M";
    toggle_quarter_layout = [];
    toggle_spiral_layout = [];
    toggle_spread_layout = [];
    toggle_stair_layout = [];
    toggle_three_column_layout = [];
    toggle_tile_layout = "Meta+T";
    toggle_window_floating = "Meta+F";
  };


  # Networking configuration.
  networking = {

    # Allow connections from certain port ranges (TCP).
    firewall.allowedTCPPortRanges = [
      # KDEConnect
      { from = 1714; to = 1764; }
    ];

    # Allow connections from certain port ranges (UDP).
    firewall.allowedUDPPortRanges = [
      # KDEConnect
      { from = 1714; to = 1764; }
    ];

  };
}
