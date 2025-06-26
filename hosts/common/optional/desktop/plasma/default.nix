{
  pkgs,
  ...
}:


{
  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
    };
    desktopManager = {
        plasma6 = {
          enable = true;
          enableQt5Integration = true;
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
  };

   environment.plasma6.excludePackages = [
      pkgs.kdePackages.elisa # Default KDE video player, use VLC instead
    ];

  environment.systemPackages = with pkgs; [
    # Packages installed
    (ark.override { unfreeEnableUnrar = true; })
    gwenview
    wl-clipboard # wayland clipboard client
    syncthingtray
  ] ++ (with pkgs.kdePackages; [
    qtbase
    ksystemlog
    kdegraphics-thumbnailers
    qtimageformats # attempt to fix absence of webp support
    dolphin-plugins
    ffmpegthumbs
  ]);

  # security.pam.services.login.kwallet = {
  #   enable = true;
  # };

  # networking = {
  #   # Allow connections from certain port ranges (TCP).
  #   firewall.allowedTCPPortRanges = [
  #     { from = 1714; to = 1764; } # KDEConnect
  #   ];

  #   # Allow connections from certain port ranges (UDP).
  #   firewall.allowedUDPPortRanges = [
  #     { from = 1714; to = 1764; } # KDEConnect
  #   ];
  # };
}
