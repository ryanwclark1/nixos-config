{
  pkgs,
  ...
}:

{
  imports = [
    ./theming
    ./services
    # ./wallpapers.nix
    ./xdg
    ./wayland
  ];

  # Core desktop dependencies - other packages moved to appropriate feature directories
  home.packages = with pkgs; [
    cairo # Graphics library (required by desktop components)
    libsoup_3 # HTTP library (required by desktop components) 
    webkitgtk_6_0 # Web rendering engine (required by desktop components)
  ];
}
