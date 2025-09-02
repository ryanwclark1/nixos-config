{
  imports = [
    ./panel
    ./launcher
    ./notifications
    ./media
    ./session
    ./clipboard
    ./scripts/system-menu.nix  # System menu launcher (walker-based)
    ./scripts/system-menu-rofi.nix  # System menu launcher (rofi-based)
    ./utils.nix
  ];

  # Shared window manager scripts
  home.file = {
    ".config/desktop/window-managers/shared/scripts" = {
      source = ./scripts;
      recursive = true;
      executable = true;
    };
  };
}