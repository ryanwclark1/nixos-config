{
  lib,
  pkgs,
  ...
}:


{
  # programs = {
    # thunar.enable = true;
    # dconf.enable = true;
    # kdeconnect.enable = true;
  # };

  qt = {
    enable = true;
    # platformTheme = "gnome";
    # style = "adwaita-dark";
  };

  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
      xkb.variant = "";
      # Enable the Plasma Desktop Environment.
      displayManager = {
        # Wayland is the default session.
        # defaultSession = "plasma";
        # lightdm ?
        sddm = {
          enable = true;
          # wayland.enable = true;
          # theme = "breeze";
        };
      };
      desktopManager = {
        plasma6 = {
          enable = true;
        };
      };
      libinput = {
        enable = true;
        # touchpad = {
        #   # naturalScrolling = true;
        #   scrollMethod = "twofinger";
        # };
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

  # environment.sessionVariables ={
  #   # NIXOS_OZONE_WL = "1";
  #   # Use librsvg's gdk-pixbuf loader cache file as it enables gdk-pixbuf to load SVG files (important for icons in GTK apps)
  #   GDK_PIXBUF_MODULE_FILE = lib.mkForce "$(echo ${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/*/loaders.cache)";
  # };

  environment.systemPackages = with pkgs; [
    # Packages installed
    (ark.override { unfreeEnableUnrar = true; })
    gwenview
    qt6.qtimageformats # attempt to fix absence of webp support
    wl-clipboard # wayland clipboard client
  ] ++ (with pkgs.kdePackages; [
    qt6.qtbase
    ksystemlog
  ]);

  # security.pam.services.login.kwallet = {
  #   enable = true;
  # };

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
