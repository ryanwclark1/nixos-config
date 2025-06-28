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
      
      # Use default desktop layout (no touchpad gestures)
      source = ~/.config/hypr/conf/layouts/default.conf
      
      # AMD GPU environment
      source = ~/.config/hypr/conf/environments/amd.conf
      
      # Desktop monitor configuration examples
      # Adjust these based on your actual monitor setup
      # monitor = DP-1, 3440x1440@144, 0x0, 1
      # monitor = HDMI-A-1, 1920x1080@60, 3440x0, 1
      
      # Performance decoration preset for powerful desktop
      # source = ~/.config/hypr/conf/decorations/default.conf
    '';
  };
  
  # Ensure desktop layout is used
  wayland.windowManager.hyprland.settings = {
    source = lib.mkAfter [
      "~/.config/hypr/conf/host-specific.conf"
    ];
  };
}