{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./ags
    ./cliphist
    ./hypr
    ./hypridle
    ./hyprlock
    ./hyprpaper
    # ./hyprpanel
    ./rofi
    ./wlogout
    # ./scripts/screenshot.nix
  ];

  home.file."Pictures/wallpapers" = {
    source = ../../../../hosts/common/wallpaper;
    recursive = true;
  };

  home.file.".config/.emoji" = {
    source = ./scripts/.emoji;
    executable = false;
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
    # hyprland-qtutils
    brightnessctl # Adjust screen brightness
    grim # Screenshot tool,
    grimblast
    gtk3
    gtk4
    handlr-regex
    hyprpicker
    mission-center
    networkmanagerapplet
    qalculate-gtk
    slurp # Screenshot tool, select area
    swappy # Wayland native snapshot editing tool, inspired by Snappy on macOS
    swww # Sway window switcher
    wayshot
    wf-recorder # Utility program for screen recording of wlroots-based compositors
    wl-clipboard # Wayland clipboard
    yad # Yet another dialog
    (writeShellScriptBin "applauncher-fullscreen" (builtins.readFile ./scripts/applauncher-fullscreen.sh))
    (writeShellScriptBin "cliphist-copy" (builtins.readFile ./scripts/cliphist-copy.sh))
    (writeShellScriptBin "cliphist-delete" (builtins.readFile ./scripts/cliphist-delete.sh))
    (writeShellScriptBin "dontkillsteam" (builtins.readFile ./scripts/dontkillsteam.sh))
    (writeShellScriptBin "emopicker9000" (builtins.readFile ./scripts/emopicker9000.sh))
    (writeShellScriptBin "list-hypr-bindings" (builtins.readFile ./scripts/list-hypr-bindings.sh))
    (writeShellScriptBin "microphone-status" (builtins.readFile ./scripts/microphone-status.sh))
    (writeShellScriptBin "power-big" (builtins.readFile ./scripts/power-big.sh))
    (writeShellScriptBin "rofi-launcher" (builtins.readFile ./scripts/rofi-launcher.sh))
    (writeShellScriptBin "screenshooting" (builtins.readFile ./scripts/screenshooting.sh))
    (writeShellScriptBin "update-checker" (builtins.readFile ./scripts/update-checker.sh))
    (writeShellScriptBin "web-search" (builtins.readFile ./scripts/web-search.sh))
    (writeShellScriptBin "wttr" (builtins.readFile ./scripts/wttr.sh))
    (writeShellScriptBin "yt" (builtins.readFile ./scripts/yt.sh))
  ];
}

