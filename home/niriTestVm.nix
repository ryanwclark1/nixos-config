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

  xdg.autostart.enable = lib.mkForce false;

  home.file.".zshrc".text = ''
    # Niri VM test profile
  '';
  home.file.".config/autostart/nm-applet.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';
  home.file.".config/autostart/blueman.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';
  home.file.".config/autostart/geoclue-demo-agent.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';

  programs.niri.settings.spawn-at-startup = lib.mkForce [
    {
      command = [ "kitty" ];
    }
  ];
}
