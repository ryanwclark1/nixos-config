{
  inputs,
  lib,
  pkgs,
  ...
}:
with lib;
let
  hyprPluginPkgs = inputs.hyprland-plugins.packages.${pkgs.system};
  hypr-plugin-dir = pkgs.symlinkJoin {
    name = "hyrpland-plugins";
    paths = with hyprPluginPkgs; [
      # hyprexpo
      #...plugins
    ];
  };
in

{
  programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      withUWSM = true;
      xwayland.enable = true;
  };
  environment.sessionVariables = { HYPR_PLUGIN_DIR = hypr-plugin-dir; };
  environment.variables.NIXOS_OZONE_WL = "1";
}
