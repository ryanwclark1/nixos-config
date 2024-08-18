{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  services = {
    xserver = {
      windowManager = {
        hypr = {
          enable = true;
        };
      };
    };
  };

  programs = {
    hyprland = {
      systemd.setPath.enable = false;
      xwayland.enable = true;
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    dconf.enable = lib.mkDefault true;
  };

  # xdg = {
  #   portal = {
  #     enable = true;
  #     extraPortals = with pkgs; [
  #       xdg-desktop-portal-hyprland
  #     ];
  #   };
  # };

}
