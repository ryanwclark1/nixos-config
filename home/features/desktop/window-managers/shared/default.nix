{
  imports = [
    ./panel
    ./launcher
    ./notifications
    ./media
    ./session
    ./clipboard
    ./scripts/system-menu.nix  # System menu launcher (walker-based)
    ./scripts/rofi-system-menu.nix  # System menu launcher (rofi-based)
    ./utils.nix
  ];

  # # TODO: Relocate
  # # Rofi scripts (common across window managers)
    ".local/bin/scripts/rofi/rofi-apps-unified.sh" = {
      force = true;
      source = ./scripts/rofi/rofi-apps-unified.sh;
      executable = true;
    };


  # Shared window manager scripts
  home.file = {
    ".config/desktop/window-managers/shared/scripts" = {
      source = ./scripts;
      recursive = true;
      executable = true;
    };
  };
}
