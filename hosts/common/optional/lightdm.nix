{
  pkgs,
  ...
}:

{
  services = {
    xserver = {
      enable = true;
      displayManager = {
        defaultSession = "plasma";
        autoLogin.user = "administrator";
        lightdm = {
          enable = true;
          # Theme settings
          greeters = {
            slick = {
              enable = true;
              cursorTheme = {
                package = pkgs.gnome3.adwaita-icon-theme;
                name = "HighContrast";
              };
              font = {
                package = pkgs.noto-fonts;
                name = "Noto Sans";
              };
              iconTheme = {
                package = pkgs.papirus-icon-theme;
                name = "Papirus Dark";
              };
              draw-user-backgrounds = true;
            };
          };
        };
      };
    };
  };
}