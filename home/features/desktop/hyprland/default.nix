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
    ./hyprpolkitagent
    ./rofi
    ./swaync
    ./swayosd
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
    wluma
    brightnessctl # Adjust screen brightness
    figlet # Print large characters
    grimblast # Best screenshot tool - wrapper around grim with more features
    handlr-regex
    hyprpicker
    libnotify # Notification library
    mission-center
    networkmanagerapplet
    slurp # Screenshot tool, select area
    swappy # Wayland native snapshot editing tool, inspired by Snappy on macOS
    tesseract # OCR tool
    wf-recorder # Utility program for screen recording of wlroots-based compositors
    wl-clipboard # Wayland clipboard
    xdg-desktop-portal-gtk # File picker support for portal
    yad # Yet another dialog
    pwvucontrol # Volume control GUI
    (writeShellScriptBin "cliphist-rofi-copy" (builtins.readFile ./scripts/cliphist-rofi-copy))
    (writeShellScriptBin "cliphist-rofi-img-copy" (builtins.readFile ./scripts/cliphist-rofi-img-copy))
    (writeShellScriptBin "list-hypr-bindings" (builtins.readFile ./scripts/list-hypr-bindings))
    (writeShellScriptBin "hyprland-workspace" (builtins.readFile ./scripts/hyprland-workspace))
    # (writeShellScriptBin "switch-workspace" (builtins.readFile ./scripts/switch-workspace))
    (writeShellScriptBin "screenshooting" (builtins.readFile ./scripts/screenshooting.sh))
  ];
}

