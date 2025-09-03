{ config, lib, pkgs, ... }:

{

  # Web application and browser launcher utilities - using external scripts
  home.packages = with pkgs; [
    # Main webapp launcher with profile support
    (writeShellScriptBin "launch-webapp" (''\
      PATH="${pkgs.xdg-utils}/bin:${pkgs.coreutils}/bin:${pkgs.gnused}/bin:${pkgs.libnotify}/bin:${pkgs.procps}/bin:$PATH"
      
    '' + builtins.readFile (./. + "/launch-webapp.sh")))
    
    # Smart browser launcher with fallbacks
    (writeShellScriptBin "launch-browser" (''\
      PATH="${pkgs.xdg-utils}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.libnotify}/bin:$PATH"
      
    '' + builtins.readFile (./. + "/launch-browser.sh")))
    
    # URL opener with webapp option
    (writeShellScriptBin "open-url" (''\
      PATH="${pkgs.coreutils}/bin:$PATH"
      
    '' + builtins.readFile (./. + "/open-url.sh")))
    
    # Bookmark launcher with rofi and walker support
    (writeShellScriptBin "launch-bookmarks" (''\
      PATH="${pkgs.rofi}/bin:${pkgs.walker}/bin:${pkgs.coreutils}/bin:$PATH"
      
    '' + builtins.readFile (./. + "/launch-bookmarks.sh")))
  ];

  # Download webapp icons
  home.file = {
    ".local/share/applications/icons/chatgpt.png".source = pkgs.fetchurl {
      url = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/chatgpt.png";
      sha256 = "1bgm6b0gljl9kss4f246chblw40a4h4j93bl70a6i0bi05zim22f";
    };

    ".local/share/applications/icons/youtube.png".source = pkgs.fetchurl {
      url = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/youtube.png";
      sha256 = "0lhm0d3kb97h270544ljr21w8da72a3gyqa4dgilgi01zmk24w91";
    };

    ".local/share/applications/icons/github.png".source = pkgs.fetchurl {
      url = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/github-light.png";
      sha256 = "1an7pcsyfx2sc6irj6zrxyyds4mm8s937f94fypdhml6vsqx8lh4";
    };

    ".local/share/applications/icons/outlook.png".source = pkgs.fetchurl {
      url = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/microsoft-outlook.png";
      sha256 = "1yz1s5x2i2vamw5c6d379lnldlcpmqaryrkaj545s6wn8df36x2y";
    };

    ".local/share/applications/icons/teams.png".source = pkgs.fetchurl {
      url = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/microsoft-teams.png";
      sha256 = "14qkmr3hp2wnmiwrmlmxfk4dsvar42yfk2va3hm08gsdk2aphigg";
    };
  };

  # Create webapp desktop entries
  xdg.desktopEntries = {
    chatgpt = {
      name = "ChatGPT";
      comment = "ChatGPT Web Application";
      exec = "launch-webapp https://chatgpt.com/ --profile=Default";
      terminal = false;
      type = "Application";
      icon = "${config.home.homeDirectory}/.local/share/applications/icons/chatgpt.png";
      startupNotify = true;
      categories = [ "Network" "WebBrowser" ];
    };

    youtube = {
      name = "YouTube";
      comment = "YouTube Web Application";
      exec = "launch-webapp https://youtube.com/ --profile=Default";
      terminal = false;
      type = "Application";
      icon = "${config.home.homeDirectory}/.local/share/applications/icons/youtube.png";
      startupNotify = true;
      categories = [ "AudioVideo" "Network" ];
    };

    github = {
      name = "GitHub";
      comment = "GitHub Web Application";
      exec = "launch-webapp https://github.com/ --profile=Default";
      terminal = false;
      type = "Application";
      icon = "${config.home.homeDirectory}/.local/share/applications/icons/github.png";
      startupNotify = true;
      categories = [ "Development" "Network" ];
    };

    outlook = {
      name = "Outlook";
      comment = "Microsoft Outlook Web Application";
      exec = "launch-webapp https://outlook.office.com/ --profile=\"Profile 2\"";
      terminal = false;
      type = "Application";
      icon = "${config.home.homeDirectory}/.local/share/applications/icons/outlook.png";
      startupNotify = true;
      categories = [ "Office" "Email" "Network" ];
    };

    teams = {
      name = "Microsoft Teams";
      comment = "Microsoft Teams Web Application";
      exec = "launch-webapp https://teams.microsoft.com/ --profile=\"Profile 2\"";
      terminal = false;
      type = "Application";
      icon = "${config.home.homeDirectory}/.local/share/applications/icons/teams.png";
      startupNotify = true;
      categories = [ "Office" "Network" "Chat" ];
    };
  };
}
