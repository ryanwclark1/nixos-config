{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./cliphist
    ./hypr
    ./hypridle
    ./hyprlock
    ./hyprpaper
    ./rofi
    ./swaync
    ./wal
    ./waybar
    ./waypaper
    ./wlogout
  ];


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

  home.packages = with pkgs; [
    # hyprland-qtutils
    brightnessctl # Adjust screen brightness
    figlet # Print large characters
    grim # Screenshot tool,
    grimblast
    gtk3
    gtk4
    handlr-regex
    hyprpicker
    libnotify # Notification library
    mission-center
    networkmanagerapplet
    qalculate-gtk
    slurp # Screenshot tool, select area
    swappy # Wayland native snapshot editing tool, inspired by Snappy on macOS
    swww # Sway window switcher
    tesseract # OCR tool
    wayshot
    wf-recorder # Utility program for screen recording of wlroots-based compositors
    wl-clipboard # Wayland clipboard
    yad # Yet another dialog
    (writeShellScriptBin "cliphist-rofi-copy" (builtins.readFile ./scripts/cliphist-rofi-copy))
    (writeShellScriptBin "cliphist-rofi-img-copy" (builtins.readFile ./scripts/cliphist-rofi-img-copy))
    (writeShellScriptBin "list-hypr-bindings" (builtins.readFile ./scripts/list-hypr-bindings))
    (writeShellScriptBin "hyprland-workspace" (builtins.readFile ./scripts/hyprland-workspace))
    # (writeShellScriptBin "switch-workspace" (builtins.readFile ./scripts/switch-workspace))
    (writeShellScriptBin "screenshooting" (builtins.readFile ./scripts/screenshooting.sh))
  ];
}

