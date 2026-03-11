{
  config,
  lib,
  pkgs,
  ...
}:

{
  # System menu using walker - walker-based system menu

  home.packages = with pkgs; [
    # Walker-based system menu script
    # System menu script - maintained as external file: ./walker-system-menu.sh
    (writeShellScriptBin "walker-system-menu" (
      ''
        PATH="${pkgs.walker}/bin:${pkgs.coreutils}/bin:${pkgs.libnotify}/bin:${pkgs.systemd}/bin:${pkgs.kitty}/bin:${pkgs.hyprpicker}/bin:${pkgs.wiremix}/bin:${pkgs.networkmanager}/bin:${pkgs.blueberry}/bin:${pkgs.hyprlock}/bin:${pkgs.hyprsunset}/bin:${pkgs.wdisplays}/bin:${pkgs.nautilus}/bin:${pkgs.btop}/bin:${pkgs.gnome-calculator}/bin:${pkgs.gnome-text-editor}/bin:$PATH"

      ''
      + builtins.readFile (./. + "/walker-system-menu.sh")
    ))

    # Walker keybindings menu script
    # Keybindings menu script - maintained as external file: ./walker-keybindings-menu.sh
    (writeShellScriptBin "walker-keybindings-menu" (
      ''
        PATH="${pkgs.walker}/bin:${pkgs.hyprland}/bin:${pkgs.jq}/bin:${pkgs.gawk}/bin:${pkgs.libxkbcommon}/bin:$PATH"

      ''
      + builtins.readFile (./. + "/walker-keybindings-menu.sh")
    ))
  ];
}
