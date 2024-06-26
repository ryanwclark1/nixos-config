{
  pkgs,
  ...
}:

{
  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    dconf.enable = true;
    thunar.enable = true;
  };

  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
    };
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        scrollMethod = "twofinger";
      };
    };
  };

  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland
      ];
    };
  };

  networking.networkmanager.enable = true;
}
