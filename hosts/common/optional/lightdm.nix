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
                package = pkgs.nordzy-cursor-theme;
                name = "Nordzy-cursors";
                size = 24;
              };
              font = {
                package = pkgs.noto-fonts;
                name = "Noto Sans";
              };
              iconTheme = {
                package = pkgs.nordzy-icon-theme;
                name = "Nodrzy-icon";
              };
              theme = {
                package = pkgs.nordic;
                name = "Nordic";
              };
              draw-user-backgrounds = true;
            };
          };
        };
      };
    };
  };
}