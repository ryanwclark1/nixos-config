{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    # File and system utilities
    handlr-regex # File association handler
    libnotify # Notification library
    mission-center # System monitor
    networkmanagerapplet # Network management GUI
    tesseract # OCR tool for screenshots
    xdg-desktop-portal-gtk # File picker support
    yad # Dialog tool

    # wlroots-based compositor tools
    wlr-randr # Display configuration for wlroots compositors (Hyprland, Sway, etc.)
    swaybg # Wayland wallpaper daemon
    swww # Animated wallpaper daemon
  ];
}
