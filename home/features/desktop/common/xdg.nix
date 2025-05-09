{
  config,
  # inputs,
  pkgs,
  ...
}:

{
  # use ghostty as an terminal emulator to open terminal apps (like yazi or nvim) with xdg-open
  home.packages = [
    pkgs.xdg-utils
    (
      pkgs.writeTextFile {
        name = "xdg-terminal-exec";
        destination = "/bin/xdg-terminal-exec";
        text = "#!${pkgs.runtimeShell}\nghostty -e \"$@\"";
        executable = true;
      }
    )
    pkgs.xdg-desktop-portal-hyprland
  ];

  xdg = {
    enable = true;
    autostart.enable = true;
    mime.enable = true;
    configFile."mimeapps.list".force = true;
    cacheHome = "${config.home.homeDirectory}/.cache";
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = "${config.home.homeDirectory}/.local/state";
    portal = {
      enable = true;
      xdgOpenUsePortal = true;
      extraPortals = with pkgs; [
        # inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
        # xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ];
      configPackages = [
        pkgs.hyprland
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
        XDG_CODE_DIR = "${config.xdg.userDirs.documents}/Code";
      };
    };
    desktopEntries = {
    };
    mimeApps = {
      enable = true;
      defaultApplications =
        let
          browser = [
            "google-chrome.desktop"
            "firefox.desktop"
            "zen.desktop"
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
            "nvim.desktop"
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
          "audio/*" = videoPlayers;

          "video/mp4" = videoPlayers;
          "video/mpeg" = videoPlayers;
          "video/mov" = videoPlayers;
          "video/*" = videoPlayers;

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
          "image/*" = imageViewers;

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
          "text/javascript" = codeEditors;
          "application/json" = codeEditors;
          "application/ld+json" = codeEditors;


          "application/pdf" = pdfViewers;

          #web
          "text/html" = browser;
          "x-scheme-handler/http" = browser;
          "x-scheme-handler/https" = browser;
          "application/x-extension-htm" = browser;
          "application/x-extension-html" = browser;
          "application/x-extension-shtml" = browser;
          "application/xhtml+xml" = browser;
          "application/x-extension-xhtml" = browser;
          "application/x-extension-xht" = browser;
          "x-scheme-handler/ftp" = browser;
          "x-scheme-handler/chrome" = "google-chrome.desktop";

          "inode/director" = ["yazi"];
          "application/x-xz-compressed-tar" = ["org.gnome.FileRoller.desktop"];
        };
    };
  };
}
