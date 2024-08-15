{ config, ... }:

{
  xdg = {
    enable = true;
    configFile."mimeapps.list".force = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/desktop";
      documents = "${config.home.homeDirectory}/documents";
      download = "${config.home.homeDirectory}/downloads";
      videos = "${config.home.homeDirectory}/videos";
      music = "${config.home.homeDirectory}/music";
      pictures = "${config.home.homeDirectory}/pictures";
      publicShare = "${config.home.homeDirectory}/public";
      templates = "${config.home.homeDirectory}/templates";
      extraConfig = {
        XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/screenshots";
        XDG_SCREENCAST_DIR = "${config.xdg.userDirs.videos}/screencast";
      };
    };
    mimeApps = {
      enable = true;
      defaultApplications =
        let
          browsers = [ "firefox.desktop" ];
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
          "image/svg+xml" = browsers;
          "text/html" = browsers;
        };
    };
  };
}