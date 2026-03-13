{
  inputs,
  lib,
  pkgs,
  ...
}:
with lib;
let
  hypr-plugin-dir = pkgs.symlinkJoin {
    name = "hyprland-plugins";
    # Keep empty by default: current hyprland-plugins/hyprexpo can break
    # against fast-moving Hyprland commits.
    paths = [ ];
  };
in

{
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    withUWSM = true;
    xwayland.enable = true;
  };
  environment.sessionVariables = {
    HYPR_PLUGIN_DIR = hypr-plugin-dir;
  };
  environment.variables.NIXOS_OZONE_WL = "1";
}
