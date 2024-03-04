{
  pkgs,
  ...
}:


{


  # programs.kdeconnect.enable = true;
  programs = {
    thunar.enable = true;
    dconf.enable = true;
    kdeconnect.enable = true;
  };

  services = {
    xserver = {
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
        plasma6 = {
          enable = true;
          useQtScaling = true;
        };
      };
      libinput = {
        enable = true;
        touchpad = {
          # naturalScrolling = true;
          scrollMethod = "twofinger";
        };
      };
    };
  };

  environment.sessionVariables ={
    NIXOS_OZONE_WL = "1";
  };

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
    kdePackages.kdeconnect-kde
    kdePackages.plasma-workspace
    kdePackages.plasma-workspace-wallpapers
    kdePackages.plasma-integration
    kdePackages.kwin-dynamic-workspaces
    kdePackages.krdc
    kdePackages.krfb
    kdePackages.kmousetool
    kdePackages.kconfigwidgets
    kdePackages.kwidgetsaddons
    kdePackages.applet-window-buttons
    kdePackages.bismuth
    kdePackages.discover
    kdePackages.kaccounts-integration
    kdePackages.kaccounts-providers
    kdePackages.kio-gdrive
    kdePackages.plasma-browser-integration
    kdePackages.plasma-integration
    kdePackages.qtstyleplugin-kvantum
    kdePackages.filelight
    kdePackages.qt6.qtbase
    # kdePackages.ksystemlog
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

    firefox
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
