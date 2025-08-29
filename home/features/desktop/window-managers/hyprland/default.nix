{
  config,
  pkgs,
  ...
}:
# Scripts reorganized 2025-08-20

{
  imports = [
    ./config # Consolidated configuration
    ./hypridle # Idle management
    ./hyprlock # Screen locking
    ./hyprpolkitagent # Authentication agent
    ./wal # Wallpaper automation (if hyprland-specific)1123
  ];


  home.packages = with pkgs; [
    # Hyprland-specific tools
    hyprpicker # Color picker for Hyprland
    grimblast # Enhanced screenshot tool (hyprland wrapper around grim)
    hdrop # Dropdown terminal for Hyprland

  ];
}

