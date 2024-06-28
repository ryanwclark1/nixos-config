{
  lib,
  # pkgs,
  ...
}:

{
  # environment.systemPackages = with pkgs; [
  #   epoll-shim
  # ];

  programs.dconf.enable = lib.mkDefault true;
  services = {
    xserver = {
      windowManager = {
        hypr = {
          enable = true;
        };
      };
    };
  };


  # programs = {
  #   hyprland = {
  #     systemd.setPath.enable = false;
  #     xwayland.enable = true;
  #     enable = true;
  #     package = pkgs.hyprland;
  #     portalPackage = pkgs.xdg-desktop-portal-hyprland;
  #   };
  #   mtr.enable = true;
  #   gnupg.agent = {
  #     enable = true;
  #     enableSSHSupport = true;
  #   };
  #   thunar.enable = true;
  # };

  # services = {


  # xdg = {
  #   portal = {
  #     enable = true;
  #     extraPortals = with pkgs; [
  #       xdg-desktop-portal-hyprland
  #     ];
  #   };
  # };

}
