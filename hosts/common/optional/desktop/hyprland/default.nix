{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  hyprPluginPkgs = inputs.hyprland-plugins.packages.${pkgs.system};
  hypr-plugin-dir = pkgs.symlinkJoin {
    name = "hyrpland-plugins";
    paths = with hyprPluginPkgs; [
      hyprexpo
      #...plugins
    ];
  };
in

{
  programs = {
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      # make sure to also set the portal package, so that they are in sync
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      withUWSM = true;
      xwayland.enable = true;
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

  # Hyprland plugins as system packages
  # environment.systemPackages = with pkgs; [
  #   inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprexpo
  # ];
  environment.sessionVariables.HYPR_PLUGIN_DIR = hypr-plugin-dir;

  environment.variables.NIXOS_OZONE_WL = "1";
}
