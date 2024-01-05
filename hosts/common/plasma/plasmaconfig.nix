{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
{
  options.plasmaconfig.enable = mkEnableOption "plasma configuration settings";
  config = mkIf config.plasmaconfig.enable {

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

      libsForQt5.ark
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
  };
}
