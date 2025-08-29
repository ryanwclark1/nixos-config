{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  # Only import the overlay, not the NixOS module
  # The niri program itself will be managed through home-manager
  nixpkgs.overlays = [
    inputs.niri.overlays.niri
  ];


  programs = {
    
    # Essential programs for Niri's default config
    # Note: kitty, rofi, hyprlock, swaylock are handled by home-manager
    waybar.enable = lib.mkDefault true;     # status bar
    
    # Enable dconf for settings management (needed for various desktop apps)
    dconf.enable = lib.mkDefault true;
  };

  # System services
  services = {
    # Note: mako and swayidle are home-manager services, not system services
    gnome.gnome-keyring.enable = lib.mkDefault true;  # secret service
  };
  
  security = {
    polkit.enable = true;
    # polkit authentication agent will be started by the desktop environment
  };

  environment = {
    systemPackages = with pkgs; [
      niri-unstable  # Make niri available system-wide for display managers
      swaybg  # wallpaper
      niriswitcher  # backup switcher
    ];
    
    variables.NIXOS_OZONE_WL = "1";
  };
}