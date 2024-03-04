{
  lib,
  pkgs,
  ...
}:


{
  programs = {
    thunar.enable = true;
    dconf.enable = true;
    kdeconnect.enable = true;
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
      xkb.variant = "";
      # Enable the Plasma Desktop Environment.
      displayManager = {
        # Wayland is the default session.
        defaultSession = "wayland";
        # lightdm ?
        sddm = {
          enable = true;
          wayland.enable = true;
        };
      };
      desktopManager = {
        plasma6 = {
          enable = true;
          # useQtScaling = true;
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

    # Ensure XDG portal is enabled
  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        kdePackages.xdg-desktop-portal-kde
      ];
    };
  };

  environment.sessionVariables ={
    NIXOS_OZONE_WL = "1";
    # Use librsvg's gdk-pixbuf loader cache file as it enables gdk-pixbuf to load SVG files (important for icons in GTK apps)
    GDK_PIXBUF_MODULE_FILE = lib.mkForce "$(echo ${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/*/loaders.cache)";
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
    # # Required by KInfoCenter
    # clinfo # clinfo
    # glxinfo # eglinfo, glxinfo
    # pciutils # lspci
    # vulkan-tools # vulkaninfo
    # wayland-utils # wayland-info
    # Required by Nix
    gitMinimal
    ksystemlog
    # KDE/Plasma: support spellchecking
    capitaine-cursors
    la-capitaine-icon-theme
    # libreoffice-qt
    kcalc
    gnome.gnome-boxes
    firefox
    qt6.qtimageformats # attempt to fix absence of webp support
    gnupg
    wl-clipboard # wayland clipboard client
  ] ++ (with pkgs.kdePackages; [
    plasma-workspace
    plasma-workspace-wallpapers
    plasma-integration
    kwin-dynamic-workspaces
    krdc
    krfb
    kgpg # add kgpg
    kmousetool
    kconfigwidgets
    kwidgetsaddons
    discover
    kaccounts-integration
    kaccounts-providers
    kio-gdrive
    plasma-browser-integration
    plasma-integration
    qtstyleplugin-kvantum
    filelight
    qt6.qtbase
    kwallet
    ksystemlog
  ]);

  security.pam.services.login.kwallet = {
    enable = true;
  };

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
