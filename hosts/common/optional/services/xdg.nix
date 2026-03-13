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

    # Keep portal backends minimal on Hyprland to avoid duplicate DBus providers.
    extraPortals = with pkgs; [
      # GTK portal fallback for apps that do not fully support Hyprland portal.
      xdg-desktop-portal-gtk
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
