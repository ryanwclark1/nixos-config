{
  ...
}:


{

  programs = {
    hyprland = {
      enable = true;
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
      # This is included in gpu.nix to allow for other drivers
      # videoDrivers = [ "amdgpu" ];
      displayManager = {
        defaultSession = "hyprland";
        sddm = {
          enable = true;
          theme = "breeze";
          wayland.enable = true;
          autoLogin.relogin = true;
        };

      };

    };

  };


  environment.variables.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    PATH = [
      "\${HOME}/.local/bin"
      "\${HOME}/.cargo/bin"
      "\$/usr/local/bin"
    ];
    NIXPKGS_ALLOW_UNFREE = "1";
    # SCRIPTDIR = "\${HOME}/.local/share/scriptdeps";
    # STARSHIP_CONFIG = "\${HOME}/.config/starship/starship.toml";
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

}
