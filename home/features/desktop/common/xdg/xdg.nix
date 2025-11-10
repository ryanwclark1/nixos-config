{
  config,
  inputs,
  pkgs,
  ...
}:

{
  # use ghostty as an terminal emulator to open terminal apps (like yazi or nvim) with xdg-open
  # home.packages = [
  #   pkgs.xdg-utils
  #   (
  #     pkgs.writeTextFile {
  #       name = "xdg-terminal-exec";
  #       destination = "/bin/xdg-terminal-exec";
  #       text = "#!${pkgs.runtimeShell}\nghostty -e \"$@\"";
  #       executable = true;
  #     }
  #   )
  #   inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland
  # ];

  xdg = {
    enable = true;
    autostart.enable = true;
    mime.enable = true;
    configFile."mimeapps.list" = {
      force = true;
    };
    cacheHome = "${config.home.homeDirectory}/.cache";
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = "${config.home.homeDirectory}/.local/state";
    # Portal configuration moved to system level to avoid conflicts
    # See: hosts/common/optional/services/xdg.nix
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
        XDG_MAIL_DIR = "${config.home.homeDirectory}/Maildir";
        XDG_CONTACT_DIR = "${config.home.homeDirectory}/Contacts";
        XDG_CALENDAR_DIR = "${config.home.homeDirectory}/Calendars";
        XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/Screenshots";
        XDG_SCREENCAST_DIR = "${config.xdg.userDirs.videos}/Screencast";
        XDG_CODE_DIR = "${config.home.homeDirectory}/Code";
        XDG_NOTES_DIR = "${config.home.homeDirectory}/Notes";
      };
    };
    # desktopEntries = {
    # };
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

          audioPlayers = [
            "mpv.desktop"
            "vlc.desktop"
          ];

          videoPlayers = [
            "mpv.desktop"
            "vlc.desktop"
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
          "audio/mp3" = audioPlayers;
          "audio/aac" = audioPlayers;
          "audio/wav" = audioPlayers;
          "audio/*" = audioPlayers;

          "application/ogg" = videoPlayers;
          "video/3gpp" = videoPlayers;
          "video/3gpp2" = videoPlayers;
          "video/mov" = videoPlayers;
          "video/mp4" = videoPlayers;
          "video/mpeg" = videoPlayers;
          "video/ogg" = videoPlayers;
          "video/quicktime" = videoPlayers;
          "video/webm" = videoPlayers;
          "video/x-flv" = videoPlayers;
          "video/x-matroska" = videoPlayers;
          "video/x-ms-asf" = videoPlayers;
          "video/x-ms-wmv" = videoPlayers;
          "video/x-msvideo" = videoPlayers;
          "video/x-ogm+ogg" = videoPlayers;
          "video/x-theora+ogg" = videoPlayers;
          "video/*" = videoPlayers;

          #images
          "image/bmp" = imageViewers;
          "image/gif" = imageViewers;
          "image/heic" = imageViewers;
          "image/heif" = imageViewers;
          "image/jpeg" = imageViewers;
          "image/jpg" = imageViewers;
          "image/png" = imageViewers;
          "image/tiff" = imageViewers;
          "image/webp" = imageViewers;
          "image/x-bmp" = imageViewers;
          "image/x-ico" = imageViewers;
          "image/*" = imageViewers;

          #vscode for text etc
          "application/json" = codeEditors;
          "application/ld+json" = codeEditors;
          "application/x-shellscript" = codeEditors;
          "application/xml" = codeEditors;
          "text/css" = codeEditors;
          "text/english" = codeEditors;
          "text/javascript" = codeEditors;
          "text/plain" = codeEditors;
          "text/x-c" = codeEditors;
          "text/x-c++" = codeEditors;
          "text/x-c++hdr" = codeEditors;
          "text/x-c++src" = codeEditors;
          "text/x-chdr" = codeEditors;
          "text/x-csrc" = codeEditors;
          "text/x-diff" = codeEditors;
          "text/x-dsrc" = codeEditors;
          "text/x-haskell" = codeEditors;
          "text/x-java" = codeEditors;
          "text/x-makefile" = codeEditors;
          "text/x-moc" = codeEditors;
          "text/x-pascal" = codeEditors;
          "text/x-pcs-gcd" = codeEditors;
          "text/x-perl" = codeEditors;
          "text/x-python" = codeEditors;
          "text/x-scala" = codeEditors;
          "text/x-scheme" = codeEditors;
          "text/x-tcl" = codeEditors;
          "text/x-tex" = codeEditors;
          "text/xml" = codeEditors;


          "application/pdf" = pdfViewers;

          #web
          "application/x-extension-htm" = browser;
          "application/x-extension-html" = browser;
          "application/x-extension-shtml" = browser;
          "application/x-extension-xht" = browser;
          "application/x-extension-xhtml" = browser;
          "application/xhtml+xml" = browser;
          "x-scheme-handler/chrome" = "google-chrome.desktop";
          "x-scheme-handler/ftp" = browser;
          "x-scheme-handler/http" = browser;
          "x-scheme-handler/https" = browser;
        };
    };
  };
}
