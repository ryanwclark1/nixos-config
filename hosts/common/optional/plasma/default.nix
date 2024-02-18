{
  pkgs,
  ...
}:


{
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    xkb.variant = "";
    # Enable the Plasma Desktop Environment.
    displayManager = {
      defaultSession = "plasmawayland";
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };
    desktopManager = {
      plasma5 = {
        enable = true;
        useQtScaling = true;
      };
    };
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        scrollMethod = "twofinger";
      };
    };
  };

  programs.kdeconnect.enable = true;
  programs.thunar.enable = true;

  environment.systemPackages = with pkgs; [
    # Packages installed

    (ark.override { unfreeEnableUnrar = true; })
    gwenview
    # Theme
    utterly-nord-plasma
    nordic
    keepassxc
    kget
    kgpg
    krename
    hyphen
    okular
    qalculate-gtk
    # Required by KInfoCenter
    clinfo # clinfo
    glxinfo # eglinfo, glxinfo
    pciutils # lspci
    vulkan-tools # vulkaninfo
    wayland-utils # wayland-info
    # Required by Nix
    gitMinimal
    libsForQt5.kdeconnect-kde
    libsForQt5.plasma-workspace
    libsForQt5.plasma-workspace-wallpapers
    libsForQt5.plasma-integration
    libsForQt5.kwin-dynamic-workspaces
    libsForQt5.krdc
    libsForQt5.krfb
    libsForQt5.kmousetool
    libsForQt5.kconfigwidgets
    libsForQt5.kwidgetsaddons
    libsForQt5.applet-window-buttons
    libsForQt5.bismuth
    libsForQt5.discover
    libsForQt5.kaccounts-integration
    libsForQt5.kaccounts-providers
    libsForQt5.kio-gdrive
    libsForQt5.plasma-browser-integration
    libsForQt5.plasma-integration
    libsForQt5.qtstyleplugin-kvantum
    libsForQt5.filelight
    libsForQt5.qt5.qtbase
    # libsForQt5.ksystemlog
    ksystemlog
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
    # libreoffice-qt

    kcalc
    gnome.gnome-boxes

  ];

  networking = {
    # Allow connections from certain port ranges (TCP).
    firewall.allowedTCPPortRanges = [
      { from = 1714; to = 1764; } # KDEConnect
    ];

    # Allow connections from certain port ranges (UDP).
    firewall.allowedUDPPortRanges = [
      { from = 1714; to = 1764; } # KDEConnect
    ];
  };

}
