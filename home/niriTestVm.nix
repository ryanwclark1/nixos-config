{
  lib,
  ...
}:

{
  imports = [
    ./global/home.nix

    ./features/kitty
    ./features/ssh

    ./features/desktop/common
    ./features/desktop/window-managers/shared/clipboard
    ./features/desktop/window-managers/shared/panel/quickshell
    ./features/desktop/window-managers/niri
  ];

  features.quickshell.enable = true;

  home.file.".zshrc".text = ''
    # Niri VM test profile
  '';

  programs.niri.settings.spawn-at-startup = lib.mkAfter [
    {
      command = [ "kitty" ];
    }
  ];
}
