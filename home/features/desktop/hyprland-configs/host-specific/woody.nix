{
  ...
}:

{
  # Woody (Desktop) specific Hyprland settings
  home.file.".config/hypr/conf/host-specific.conf" = {
    text = ''
      # -----------------------------------------------------
      # Host-specific configuration for Woody (Desktop)
      # -----------------------------------------------------

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
}