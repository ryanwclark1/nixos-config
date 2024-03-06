{
  lib,
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
      xkb.variant = "";
      libinput.enable = true;
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

  # DO NOT USE ON OTHER DEs
  # qt.style = "kvantum";
  # qt.platformTheme = "qt5ct";


  # Use librsvg's gdk-pixbuf loader cache file as it enables gdk-pixbuf to load SVG files (important for icons in GTK apps)
  # environment.variables.sessionVariables = {
  #   # GDK_PIXBUF_MODULE_FILE = lib.mkForce "$(echo ${pkgs.librsvg.out}/lib/gdk-pixbuf-2.0/*/loaders.cache)";
  #   # NIXOS_OZONE_WL = "1";
  #   PATH = [
  #     "\${HOME}/.local/bin"
  #     "\${HOME}/.cargo/bin"
  #     "\$/usr/local/bin"
  #   ];
  #   # NIXPKGS_ALLOW_UNFREE = "1";
  #   # SCRIPTDIR = "\${HOME}/.local/share/scriptdeps";
  #   # STARSHIP_CONFIG = "\${HOME}/.config/starship/starship.toml";
  #   XDG_CURRENT_DESKTOP = "Hyprland";
  #   XDG_SESSION_TYPE = "wayland";
  #   XDG_SESSION_DESKTOP = "Hyprland";
  #   GDK_BACKEND = "wayland";
  #   CLUTTER_BACKEND = "wayland";
  #   SDL_VIDEODRIVER = "x11";
  #   XCURSOR_SIZE = "24";
  #   XCURSOR_THEME = "Bibata-Modern-Ice";
  #   QT_QPA_PLATFORM = "wayland";
  #   # QT_QPA_PLATFORMTHEME = "qt5ct";
  #   QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  #   QT_AUTO_SCREEN_SCALE_FACTOR = "1";
  #   # MOZ_ENABLE_WAYLAND = "1";
  # };

}
