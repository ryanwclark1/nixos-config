{
  imports = [
    ./panel
    ./launcher
    ./notifications
    ./media
    ./session
    ./clipboard
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