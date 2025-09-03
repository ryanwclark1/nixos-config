{
  pkgs,
  inputs,
  ...
}:

{
  # XDG Desktop Portal configuration for Hyprland
  # Provides integration between applications and the desktop environment
  xdg.portal = {
    enable = true;

    # Use XDG portal for file opening (better integration)
    xdgOpenUsePortal = true;

    # Configure portal backends for different desktop environments
    config = {
      # Default portal for common applications
      common.default = [ "gtk" ];

      # Hyprland-specific portal configuration
      hyprland.default = [
        "hyprland"
        "gtk"
      ];

      # Fallback for other desktop environments
      gnome.default = [ "gtk" ];
      kde.default = [ "kde" ];
      xfce.default = [ "gtk" ];
    };

    # Install additional portal backends for complete functionality
    extraPortals = with pkgs; [
      # Hyprland portal (primary for Wayland)
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland

      # GTK portal (fallback and X11 support)
      xdg-desktop-portal-gtk

      # KDE portal (for KDE applications)
      kdePackages.xdg-desktop-portal-kde

      # Additional portals for specific functionality
      xdg-desktop-portal-gnome # GNOME applications
      xdg-desktop-portal-wlr # WLRoots compatibility
    ];
  };

  # Enable additional XDG utilities for better desktop integration
  environment.systemPackages = with pkgs; [
    # XDG utilities for desktop integration
    xdg-utils

    # Additional tools for XDG compliance
    xdg-user-dirs
    xdg-user-dirs-gtk
  ];
}
