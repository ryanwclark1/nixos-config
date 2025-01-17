{
  config,
  inputs,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    xdg-utils
  ];

  xdg = {
    enable = true;
    mime.enable = true;
    configFile."mimeapps.list".force = true;
    cacheHome = "${config.home.homeDirectory}/.local/cache";
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = "${config.home.homeDirectory}/.local/state";
    portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
      ];
      config = {
        common = {
          default = [
            "hyprland"
            "gtk"
          ];
        };
      };
    };
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
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      publicShare = "${config.home.homeDirectory}/Public";
      templates = "${config.home.homeDirectory}/Templates";
      videos = "${config.home.homeDirectory}/Videos";
      extraConfig = {
        XDG_MAIL_DIR = "${config.home.homeDirectory}/Mail";
        XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/Screenshots";
        XDG_SCREENCAST_DIR = "${config.xdg.userDirs.videos}/Screencast";
      };
    };
    desktopEntries = {
    };
    mimeApps = {
      enable = true;
      defaultApplications =
        let
          browser = [
            "zen.desktop"
            "google-chrome.desktop"
            "firefox.desktop"
            "chromium.desktop"
          ];

          videoPlayers = [
            "mpv"
            "vlc"
          ];

          imageViewers = [
            "imv.desktop"
            "eog.desktop"
          ];

          codeEditors = [
            "code.desktop"
          ];

          pdfViewers = [
            "zathura.desktop"
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

          "application/pdf" = pdfViewers;

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