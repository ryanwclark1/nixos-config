{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    wluma
    brightnessctl # Adjust screen brightness
  ];

  # Frametop (Framework laptop) specific Hyprland settings
  home.file.".config/hypr/conf/host-specific.conf" = {
    text = ''
      # -----------------------------------------------------
      # Host-specific configuration for Frametop (Framework laptop)
      # -----------------------------------------------------

      # Platform-specific variables for laptop
      $IS_LAPTOP = true
      $IS_HIDPI = true
      $IS_NVIDIA = false
      $IS_AMD = false

      # Use laptop layout with touchpad gestures
      source = ~/.config/hypr/conf/layouts/laptop.conf

      # Intel GPU environment (default is fine for Intel)
      source = ~/.config/hypr/conf/environments/default.conf

      # Framework laptop typically has HiDPI display
      # Adjust if your model differs
      monitor = eDP-1, 2256x1504@60, 0x0, 1.0

      # Laptop-specific keybindings
      # bind = , XF86Launch1, exec, ags -t launcher  # Framework key
    '';
  };

  # Note: Using system-level Hyprland with UWSM
  # Host-specific configuration is automatically loaded via host-specific.conf
  # No need for wayland.windowManager.hyprland.settings when using system-level Hyprland

  # SwayOSD configuration for frametop (Framework laptop)
  # services.swayosd = {
  #   enable = true;
  #   display = "eDP-1";  # Framework laptop internal display
  # };
}
