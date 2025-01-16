{
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
      package = (pkgs.hyprland.override { # or inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland
        enableXWayland = true;  # whether to enable XWayland
        legacyRenderer = false; # whether to use the legacy renderer (for old GPUs)
        withSystemd = true;     # whether to build with systemd support
      });
      # systemd.setPath.enable = true;
      # xwayland.enable = true;
      # portalPackage = pkgs.xdg-desktop-portal-hyprland;
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
        xdg-desktop-portal-hyprland
      ];
    };
  };

}
