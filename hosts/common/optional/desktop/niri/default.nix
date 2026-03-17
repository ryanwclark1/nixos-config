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

  # Hyprland already provides a user polkit agent via Home Manager.
  # Prevent niri-flake from starting a second agent in the same session.
  systemd.user.services.niri-flake-polkit.wantedBy = lib.mkForce [ ];


  # System services
  services = {
    gnome.gnome-keyring.enable = lib.mkDefault true;  # secret service
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
