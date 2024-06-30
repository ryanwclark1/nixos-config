{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  # environment.systemPackages = with pkgs; [
  #   epoll-shim
  # ];

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
    thunar.enable = true;
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
