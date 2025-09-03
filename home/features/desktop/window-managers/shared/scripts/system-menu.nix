{
  config,
  lib,
  pkgs,
  ...
}:

{
  # System menu using walker - adapted from omarchy-menu for NixOS
  
  home.packages = with pkgs; [
    # Main system menu script
    # System menu script - maintained as external file: ./system-menu.sh
    (writeShellScriptBin "system-menu" (''
      PATH="${pkgs.walker}/bin:${pkgs.coreutils}/bin:${pkgs.libnotify}/bin:${pkgs.systemd}/bin:${pkgs.kitty}/bin:${pkgs.hyprpicker}/bin:${pkgs.satty}/bin:${pkgs.hyprshot}/bin:${pkgs.wiremix}/bin:${pkgs.networkmanager}/bin:${pkgs.blueberry}/bin:${pkgs.hyprlock}/bin:${pkgs.hyprsunset}/bin:${pkgs.wdisplays}/bin:${pkgs.nautilus}/bin:${pkgs.btop}/bin:${pkgs.gnome-calculator}/bin:${pkgs.gnome-text-editor}/bin:$PATH"
      
    '' + builtins.readFile (./. + "/system-menu.sh")))
  ];
}