{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
with lib;

{
  imports = [
    ./hyprlandconfig.nix
  ];

  options.hyprland.enable = mkEnableOption "hyprland settings";
  config = mkIf config.hyprland.enable {
    hyprlandconfig.enable = true;

    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    programs.mtr.enable = true;
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    services.fstrim.enable = true;
    services.xserver = {
      enable = true;
      layout = "us";
      xkbVariant = "";
      libinput.enable = true;
      # This is included in gpu.nix to allow for other drivers
      # videoDrivers = [ "amdgpu" ];
      displayManager.gdm = {
        enable = true;
        wayland = true;
      };
    };
    sound.enable = true;
    security.rtkit.enable = true;
    programs.thunar.enable = true;
    services.gvfs.enable = true;
    services.tumbler.enable = true;

    environment.variables={
     NIXOS_OZONE_WL = "1";
     PATH = [
       "\${HOME}/.local/bin"
       "\${HOME}/.cargo/bin"
       "\$/usr/local/bin"
     ];
     NIXPKGS_ALLOW_UNFREE = "1";
     SCRIPTDIR = "\${HOME}/.local/share/scriptdeps";
     STARSHIP_CONFIG = "\${HOME}/.config/starship/starship.toml";
     XDG_CURRENT_DESKTOP = "Hyprland";
     XDG_SESSION_TYPE = "wayland";
     XDG_SESSION_DESKTOP = "Hyprland";
     GDK_BACKEND = "wayland";
     CLUTTER_BACKEND = "wayland";
     SDL_VIDEODRIVER = "x11";
     XCURSOR_SIZE = "24";
     XCURSOR_THEME = "Bibata-Modern-Ice";
     QT_QPA_PLATFORM = "wayland";
     QT_QPA_PLATFORMTHEME = "qt5ct";
     QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
     QT_AUTO_SCREEN_SCALE_FACTOR = "1";
     MOZ_ENABLE_WAYLAND = "1";
    };
  };

}