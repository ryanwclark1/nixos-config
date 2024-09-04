{ config, ... }:

{
  xdg = {
    enable = true;
    configFile."mimeapps.list".force = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      videos = "${config.home.homeDirectory}/Videos";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      publicShare = "${config.home.homeDirectory}/Public";
      templates = "${config.home.homeDirectory}/Templates";
      extraConfig = {
        XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/Screenshots";
        XDG_SCREENCAST_DIR = "${config.xdg.userDirs.videos}/Screencast";
      };
    };
    mimeApps =
    {
      enable = true;
      defaultApplications =
        let
          browser = ["firefox.desktop"];
          videoPlayers = [
            "mpv.desktop"
            "umpv.desktop"
          ];
          imageViewers = [ "imv.desktop" ];
          textEditors = [ "videoPlayers.desktop" ];
        in
        {
          "audio/mp3" = videoPlayers;
          "audio/aac" = videoPlayers;
          "audio/wav" = videoPlayers;
          "video/mp4" = videoPlayers;
          "video/mpeg" = videoPlayers;

          "image/png" = imageViewers;
          "image/jpeg" = imageViewers;
          "image/gif" = imageViewers;
          "image/webp" = imageViewers;

          "text/plain" = textEditors;

          "text/csv" = [ "libreoffice" ];
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [ "libreoffice" ];
          "application/vnd.ms-excel" = [ "libreoffice" ];
          "application/msword" = [ "libreoffice" ];
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [
            "libreoffice"
          ];
          "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [
            "libreoffice"
          ];
          "application/vnd.ms-powerpoint" = [ "libreoffice" ];
          # "application/pdf" = [ "wps-office-pdf.desktop" ];
          "image/svg+xml" = browser;
          "text/html" = browser;
          "x-scheme-handler/http" = browser;
          "x-scheme-handler/https" = browser;
          "x-scheme-handler/about" = browser;
          "x-scheme-handler/unknown" = browser;
        };
    };
  };
}