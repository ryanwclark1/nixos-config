{ config, lib, pkgs, ... }:

{
  # Custom webapp launcher script (adapted from omarchy-launch-webapp)
  home.packages = with pkgs; [
    (writeShellScriptBin "launch-webapp" ''
      #!/usr/bin/env bash
      
      # Get the default browser
      browser=$(${pkgs.xdg-utils}/bin/xdg-settings get default-web-browser 2>/dev/null || echo "")
      
      # Fallback to available browsers in order of preference
      case $browser in
        google-chrome* | brave-browser* | microsoft-edge* | opera* | vivaldi*) ;;
        *) 
          # Try to find an available browser
          if command -v google-chrome-stable >/dev/null; then
            browser="google-chrome.desktop"
          elif command -v brave >/dev/null; then
            browser="brave-browser.desktop"  
          elif command -v chromium >/dev/null; then
            browser="chromium.desktop"
          elif command -v firefox >/dev/null; then
            browser="firefox.desktop"
          else
            echo "Error: No suitable browser found for webapp mode"
            exit 1
          fi
          ;;
      esac
      
      # Find the browser executable
      browser_exec=$(${pkgs.gnused}/bin/sed -n 's/^Exec=\([^ ]*\).*/\1/p' \
        ~/.local/share/applications/$browser \
        ~/.nix-profile/share/applications/$browser \
        /run/current-system/sw/share/applications/$browser \
        2>/dev/null | head -1)
      
      if [[ -z "$browser_exec" ]]; then
        # Fallback to direct command names
        case $browser in
          google-chrome*) browser_exec="google-chrome-stable" ;;
          brave-browser*) browser_exec="brave" ;;  
          chromium*) browser_exec="chromium" ;;
          firefox*) browser_exec="firefox" ;;
          *) browser_exec="chromium" ;;
        esac
      fi
      
      # Launch the webapp
      if command -v "$browser_exec" >/dev/null; then
        exec setsid "$browser_exec" --app="$1" "''${@:2}" &
      else
        echo "Error: Browser executable '$browser_exec' not found"
        exit 1
      fi
    '')
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
  };

  # Create webapp desktop entries
  xdg.desktopEntries = {
    chatgpt = {
      name = "ChatGPT";
      comment = "ChatGPT Web Application";
      exec = "launch-webapp https://chatgpt.com/";
      terminal = false;
      type = "Application";
      icon = "${config.home.homeDirectory}/.local/share/applications/icons/chatgpt.png";
      startupNotify = true;
      categories = [ "Network" "WebBrowser" ];
    };

    youtube = {
      name = "YouTube";
      comment = "YouTube Web Application";
      exec = "launch-webapp https://youtube.com/";
      terminal = false;
      type = "Application";
      icon = "${config.home.homeDirectory}/.local/share/applications/icons/youtube.png";
      startupNotify = true;
      categories = [ "AudioVideo" "Network" ];
    };

    github = {
      name = "GitHub";
      comment = "GitHub Web Application";
      exec = "launch-webapp https://github.com/";
      terminal = false;
      type = "Application"; 
      icon = "${config.home.homeDirectory}/.local/share/applications/icons/github.png";
      startupNotify = true;
      categories = [ "Development" "Network" ];
    };
  };
}