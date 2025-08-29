{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      # make sure to also set the portal package, so that they are in sync
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      withUWSM = true;
      xwayland.enable = true;
      # Plugins need to be handled differently for system-level Hyprland
      # plugins = [
      #   inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprexpo
      # ];
    };
    mtr.enable = lib.mkDefault true;
    gnupg.agent = {
      enable = lib.mkDefault true;
      enableSSHSupport = true;
    };
    dconf.enable = lib.mkDefault true;
    seahorse.enable = lib.mkDefault true;
  };

  security.polkit.enable = lib.mkDefault true;

  environment.variables.NIXOS_OZONE_WL = "1";
}
