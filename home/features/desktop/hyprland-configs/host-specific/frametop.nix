{
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

      # Use laptop layout with touchpad gestures
      source = ~/.config/hypr/conf/layouts/laptop.conf

      # Intel GPU environment (if needed)
      # source = ~/.config/hypr/conf/environments/default.conf

      # Framework laptop typically has HiDPI display
      # Adjust if your model differs
      # monitor = eDP-1, 2256x1504@60, 0x0, 1.5

      # Laptop-specific keybindings
      # bind = , XF86Launch1, exec, ags -t launcher  # Framework key
    '';
  };
}