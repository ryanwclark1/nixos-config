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
                package = pkgs.gnome.adwaita-icon-theme;
                name = "Adwaita";
                size = 24;
              };
              font = {
                package = pkgs.noto-fonts;
                name = "Noto Sans";
              };
              iconTheme = {
                package = pkgs.papirus-icon-theme;
                name = "Papirus Dark";
              };
              draw-user-backgrounds = false;
            };
          };
        };
      };
    };
  };
}