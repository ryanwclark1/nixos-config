{
  inputs,
  lib,
  pkgs,
  ...
}:

{

  imports = [
    inputs.niri.nixosModules.niri
  ];

  programs = {
    niri.enable = true;  # Enable niri at system level to register the session
    
    # Enable dconf for settings management (needed for various desktop apps)
    dconf.enable = lib.mkDefault true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # System services
  services = {
    gnome.gnome-keyring.enable = lib.mkDefault true;  # secret service
  };

  security = {
    polkit.enable = true;
  };

  hardware.graphics = { enable = true; enable32Bit = true; };

  environment = {
    systemPackages = with pkgs; [
      # niri package is automatically provided by programs.niri.enable
      niriswitcher  # backup switcher
    ];

    variables.NIXOS_OZONE_WL = "1";
  };
}
