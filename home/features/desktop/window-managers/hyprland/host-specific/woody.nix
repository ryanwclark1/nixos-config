{
  config,
  lib,
  ...
}:

{
  # Woody (Desktop) specific Hyprland settings
  home.file.".config/hypr/conf/host-specific.conf" = {
    text = ''
      # -----------------------------------------------------
      # Host-specific configuration for Woody (Desktop)
      # -----------------------------------------------------

      # Platform-specific variables for desktop
      $IS_LAPTOP = false
      $IS_HIDPI = false
      $IS_NVIDIA = false
      $IS_AMD = true

      # Use default desktop layout (no touchpad gestures)
      source = ~/.config/hypr/conf/layouts/default.conf

      # AMD GPU environment
      source = ~/.config/hypr/conf/environments/amd.conf

      # AORUS FO48U 4K OLED Monitor Configuration
      monitor = DP-1, 3840x2160@120, 0x0, 1

      # Performance decoration preset for powerful desktop
      # source = ~/.config/hypr/conf/decorations/default.conf
    '';
  };

  # Note: Using system-level Hyprland with UWSM  
  # Host-specific configuration is automatically loaded via host-specific.conf
  # No need for wayland.windowManager.hyprland.settings when using system-level Hyprland

    # SwayOSD configuration for woody (Desktop)
  # services.swayosd = {
  #   enable = true;
  #   display = "DP-1";  # Desktop monitor via DisplayPort
  # };
}
