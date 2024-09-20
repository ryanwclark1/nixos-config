{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./cliphist
    ./dunst
    # ./eww
    ./hypridle
    ./hypr
    ./hyprlock
    # ./mako
    ./rofi
    ./swaync
    ./waybar
    ./imv.nix
    # ./wofi.nix
  ];

  home = {
    file."Pictures/wallpapers" = {
      source = ../../../../hosts/common/wallpaper;
      recursive = true;
    };
    file.".config/swappy/config" = {
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

    packages = with pkgs; [
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
      (import ./scripts/wallsetter.nix { inherit pkgs; })
      (import ./scripts/microphone-status.nix { inherit pkgs; })
      (import ./scripts/update-checker.nix { inherit pkgs; })
    ];
  };
}

