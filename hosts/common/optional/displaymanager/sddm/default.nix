{
  lib,
  pkgs,
  ...
}:
let
  # sddmTheme = "breeze";
  sddmTheme = import ./sddm-theme.nix { inherit pkgs; };
in
{

  environment.systemPackages = with pkgs; [
    sddm-astronaut
    (catppuccin-sddm.override {
      flavor = "frappe";
      font = "Fira Sans";
      fontSize = "10";
      # background = "/path/to/your/wallpaper.jpg";
      loginBackground = false;
    })
  ];

  services = {
    xserver.enable = lib.mkDefault true;
    displayManager = {
      defaultSession = lib.mkDefault "hyprland-uwsm";
      sddm = {
        enable = true;
        wayland = {
          enable = true;
          compositor = "weston";
        };
        autoNumlock = true;
        enableHidpi = true;
        # theme "= "${sddmTheme}";
        package = pkgs.kdePackages.sddm;
        theme = "catppuccin-frappe";
        settings.Theme.CursorTheme = "Bibata-Modern-Classic";
        extraPackages = with pkgs; [
          kdePackages.qtmultimedia
          kdePackages.qtsvg
          kdePackages.qtvirtualkeyboard
        ];
      };
    };
  };
}
