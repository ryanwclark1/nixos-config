{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./ags
    ./cliphist
    # ./dunst
    ./eww
    ./hypr
    ./hypridle
    ./hyprlock
    ./rofi
    # ./swaync
    ./wlogout
    ./waybar
    # ./scripts/screenshot.nix
    # ./eww
    # ./mako

  ];

  home.file."Pictures/wallpapers" = {
      source = ../../../../hosts/common/wallpaper;
      recursive = true;
  };

  home.file.".config/swappy/config" = {
    text = ''
      [Default]
      save_dir="${config.home.homeDirectory}/Pictures/Screenshots"
      save_filename_format=swappy-%Y%m%d-%H%M%S.png
      show_panel=false
      line_size=5
      text_size=20
      text_font=Ubuntu
      paint_mode=brush
      early_exit=true
      fill_shape=false
    '';
  };

  home.file.".config/hypr/binds.py" = {
    source = ./scripts/binds.py;
    executable = true;
  };

  home.packages = with pkgs; [
    brightnessctl
    wf-recorder # Utility program for screen recording of wlroots-based compositors
    wl-clipboard # Wayland clipboard
    grim # Screenshot tool,
    slurp # Screenshot tool, select area
    grimblast
    hyprpicker
    swww # Sway window switcher
    yad # Yet another dialog
    brightnessctl # Adjust screen brightness
    swappy # Wayland native snapshot editing tool, inspired by Snappy on macOS
    networkmanagerapplet
    mission-center
    qalculate-gtk
    wayshot
    gtk3
    (import ./scripts/applauncher-fullscreen.nix { inherit pkgs; })
    (import ./scripts/cliphist-copy.nix { inherit pkgs; })
    (import ./scripts/cliphist-delete.nix { inherit pkgs; })
    (import ./scripts/list-hypr-bindings.nix { inherit pkgs; })
    (import ./scripts/microphone-status.nix { inherit pkgs; })
    (import ./scripts/power-big.nix { inherit pkgs; })
    (import ./scripts/rofi-launcher.nix { inherit pkgs; })
    (import ./scripts/screenshooting.nix { inherit pkgs; })
    (import ./scripts/task-waybar.nix { inherit pkgs; })
    (import ./scripts/update-checker.nix { inherit pkgs; })
    (import ./scripts/wallsetter.nix { inherit pkgs; })
    (import ./scripts/web-search.nix { inherit pkgs; })
    (import ./scripts/wttr.nix { inherit pkgs; })
    (import ./scripts/yt.nix { inherit pkgs; })
  ];
}

