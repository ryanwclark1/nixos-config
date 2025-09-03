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
    # Rofi system menu script - maintained as external file: ./system-menu-rofi.sh
    (writeShellScriptBin "system-menu-rofi" (''
      PATH="${pkgs.rofi-wayland}/bin:${pkgs.coreutils}/bin:${pkgs.libnotify}/bin:${pkgs.systemd}/bin:${pkgs.kitty}/bin:${pkgs.hyprpicker}/bin:${pkgs.blueberry}/bin:${pkgs.hyprlock}/bin:${pkgs.hyprsunset}/bin:${pkgs.wdisplays}/bin:${pkgs.wiremix}/bin:${pkgs.nautilus}/bin:${pkgs.btop}/bin:${pkgs.gnome-calculator}/bin:${pkgs.gnome-text-editor}/bin:${pkgs.gnome-control-center}/bin:$PATH"
      
    '' + builtins.readFile (./. + "/system-menu-rofi.sh")))
    
    # Quick rofi menu shortcuts
    # Quick rofi power menu - maintained as external file: ./rofi-power.sh
    (writeShellScriptBin "rofi-power" (builtins.readFile (./. + "/rofi-power.sh")))
    
    # Quick rofi capture menu - maintained as external file: ./rofi-capture.sh
    (writeShellScriptBin "rofi-capture" (builtins.readFile (./. + "/rofi-capture.sh")))
    
    # Quick rofi settings menu - maintained as external file: ./rofi-settings.sh
    (writeShellScriptBin "rofi-settings" (builtins.readFile (./. + "/rofi-settings.sh")))
  ];
}