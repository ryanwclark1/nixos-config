{
  config,
  ...
}:

{
  services.flameshot = {
    enable = true;

    settings = {
      General = {
        drawColor = "#ff0000";
        drawFontSize = 23;
        drawThickness = 3;

        savePath = "${config.home.homeDirectory}/Downloads";
        savePathFixed = false;

        disabledTrayIcon = true;
        showDesktopNotification = false;
        showHelp = false;

        uiColor = "#ffffff";
      };
    };
  };
}