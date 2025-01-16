{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  # services = {
  #   xserver = {
  #     windowManager = {
  #       hypr = {
  #         enable = true;
  #       };
  #     };
  #   };
  # };

  programs = {
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      # make sure to also set the portal package, so that they are in sync
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      withUWSM = true;
      xwayland.enable = true;
    };
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    dconf.enable = lib.mkDefault true;
  };

  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
        xdg-desktop-portal-hyprland
      ];
    };
  };

}
