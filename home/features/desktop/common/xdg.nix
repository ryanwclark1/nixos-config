{
  config,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    xdg-utils
  ];


  xdg = {
    enable = true;
    configFile."mimeapps.list".force = true;
    cacheHome = config.home.homeDirectory + "/.local/cache";
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    systemDirs = {
      config = [ "${config.home.homeDirectory}/.config" ];
      data = [ "${config.home.homeDirectory}/.local/share" "/usr/share" "/usr/share/applications/" "/usr/local/share/applications/" ];
    };
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
    desktopEntries = {
      firefox = {
        name = "Firefox";
        genericName = "Web Browser";
        exec = "firefox %U";
        terminal = false;
        categories = [ "Application" "Network" "WebBrowser" ];
        mimeType = [
          "text/html"
          "text/xml"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
          "x-scheme-handler/chrome"
          "application/x-extension-htm"
          "application/x-extension-html"
          "application/x-extension-shtml"
          "application/xhtml+xml"
          "application/x-extension-xhtml"
          "application/x-extension-xht"
        ];
      };
      eog = {
        name = "eog";
        genericName = "Image Viewer";
        exec = "eog %U";
        terminal = false;
        categories = [ "Application" "Graphics" "Viewer" ];
        mimeType = [
          "image/png"
          "image/heic"
          "image/heif"
          "image/jpeg"
          "image/gif"
          "image/bmp"
          "image/jpg"
          "image/tiff"
          "image/x-bmp"
          "image/x-ico"
        ];
      };
    };
    mimeApps =
    {
      enable = true;
      defaultApplications =
        let
          browser = [
            "firefox.desktop"
          ];
          videoPlayers = [
            "mpv"
            "vlc"
          ];
          imageViewers = [
            "eog.desktop"
            "imv.desktop"
          ];

          codeEditors = [
            "code.desktop"
          ];
        in
        {
          #audio video
          "audio/mp3" = videoPlayers;
          "audio/aac" = videoPlayers;
          "audio/wav" = videoPlayers;
          "video/mp4" = videoPlayers;
          "video/mpeg" = videoPlayers;
          "video/mov" = videoPlayers;

          #images
          "image/png" = imageViewers;
          "image/jpeg" = imageViewers;
          "image/gif" = imageViewers;
          "image/bmp" = imageViewers;
          "image/jpg" = imageViewers;
          "image/tiff" = imageViewers;
          "image/x-bmp" = imageViewers;
          "image/x-ico" = imageViewers;
          "image/heic" = imageViewers;
          "image/heif" = imageViewers;

          #vscode for text etc
          "text/plain" = codeEditors;
          "text/x-c" = codeEditors;
          "text/x-c++" = codeEditors;
          "text/x-c++src" = codeEditors;
          "text/x-chdr" = codeEditors;
          "text/x-csrc" = codeEditors;
          "text/x-diff" = codeEditors;
          "text/x-dsrc" = codeEditors;
          "text/x-haskell" = codeEditors;
          "text/x-java" = codeEditors;
          "text/x-makefile" = codeEditors;
          "text/x-moc" = codeEditors;
          "text/x-pcs-gcd" = codeEditors;
          "text/x-perl" = codeEditors;
          "text/x-python" = codeEditors;
          "text/x-scala" = codeEditors;
          "text/x-scheme" = codeEditors;
          "text/css" = codeEditors;

          # "text/plain" = textEditors;
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

          #web
          "text/html" = browser;
          "x-scheme-handler/http" = browser;
          "x-scheme-handler/https" = browser;
          "x-scheme-handler/chrome" = browser;
          "application/x-extension-htm" = browser;
          "application/x-extension-html" = browser;
          "application/x-extension-shtml" = browser;
          "application/xhtml+xml" = browser;
          "application/x-extension-xhtml" = browser;
          "application/x-extension-xht" = browser;
        };
    };
  };
}