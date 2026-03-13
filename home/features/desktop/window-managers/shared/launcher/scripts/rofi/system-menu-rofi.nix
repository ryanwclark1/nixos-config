{
  config,
  lib,
  pkgs,
  ...
}:

{
  # System menu using rofi - alternative to walker-based system menu

  home.packages = with pkgs; [
    # Rofi-based system menu script - using external script file
    # Rofi system menu script - maintained as external file: ./rofi-system-menu.sh
    (writeShellScriptBin "system-menu-rofi" (''
      PATH="${pkgs.rofi}/bin:${pkgs.coreutils}/bin:${pkgs.libnotify}/bin:${pkgs.systemd}/bin:${pkgs.kitty}/bin:${pkgs.hyprpicker}/bin:${pkgs.blueman}/bin:${pkgs.hyprlock}/bin:${pkgs.hyprsunset}/bin:${pkgs.wdisplays}/bin:${pkgs.wiremix}/bin:${pkgs.nautilus}/bin:${pkgs.btop}/bin:${pkgs.gnome-calculator}/bin:${pkgs.gnome-text-editor}/bin:${pkgs.gnome-control-center}/bin:$PATH"

    '' + builtins.readFile (./. + "/rofi-system-menu.sh")))

    # Quick rofi menu shortcuts
    # Quick rofi power menu - maintained as external file: ./rofi-power.sh
    (writeShellScriptBin "rofi-power" (builtins.readFile (./. + "/rofi-power.sh")))

    # Quick rofi capture menu - maintained as external file: ./rofi-capture.sh
    (writeShellScriptBin "rofi-capture" (builtins.readFile (./. + "/rofi-capture.sh")))

    # Quick rofi settings menu - maintained as external file: ./rofi-settings.sh
    (writeShellScriptBin "rofi-settings" (builtins.readFile (./. + "/rofi-settings.sh")))

    # Quick rofi battery menu - maintained as external file: ./rofi-os-battery.sh
    (writeShellScriptBin "os-battery-rofi" (''
      PATH="${pkgs.rofi}/bin:${pkgs.coreutils}/bin:${pkgs.libnotify}/bin:${pkgs.acpi}/bin:${pkgs.upower}/bin:${pkgs.gawk}/bin:${pkgs.gnugrep}/bin:$PATH"
    '' + builtins.readFile (./. + "/rofi-os-battery.sh")))
  ];
}
