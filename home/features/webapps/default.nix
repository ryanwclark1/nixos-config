{ config, lib, pkgs, ... }:

{
  # Web application and browser launcher utilities - using external scripts
  home.packages = with pkgs; [
    # Main webapp launcher with profile support
    (writeShellScriptBin "launch-webapp" (''\
      PATH="${pkgs.xdg-utils}/bin:${pkgs.coreutils}/bin:${pkgs.gnused}/bin:${pkgs.libnotify}/bin:${pkgs.procps}/bin:$PATH"

    '' + builtins.readFile (./. + "/launch-webapp.sh")))

    # Logged webapp launcher that adds usage tracking
    (writeShellScriptBin "launch-webapp-logged" ''
      #!/usr/bin/env bash

      LOGFILE="$HOME/.local/share/webapp-usage.log"
      WEBAPP_NAME=""

      # Extract webapp name from URL
      case "$1" in
        *youtube.com*) WEBAPP_NAME="YouTube" ;;
        *chatgpt.com*) WEBAPP_NAME="ChatGPT" ;;
        *github.com*) WEBAPP_NAME="GitHub" ;;
        *outlook.office.com*) WEBAPP_NAME="Outlook" ;;
        *teams.microsoft.com*) WEBAPP_NAME="Teams" ;;
        *) WEBAPP_NAME="$(echo "$1" | sed 's|https\?://\([^/]*\).*|\1|')" ;;
      esac

      # Create log directory if it doesn't exist
      mkdir -p "$(dirname "$LOGFILE")"

      # Log the launch with timestamp and additional info
      {
        echo "$(date '+%Y-%m-%d %H:%M:%S'): Launching $WEBAPP_NAME webapp"
        echo "  URL: $1"
        echo "  Profile: ''${2#--profile=}"
        echo "  Session: $XDG_SESSION_ID"
        echo "  Desktop: $XDG_CURRENT_DESKTOP"
        echo "---"
      } >> "$LOGFILE"

      # Launch the actual webapp
      exec launch-webapp "$@"
    '')

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

    # Webapp usage log viewer
    (writeShellScriptBin "webapp-logs" ''
      #!/usr/bin/env bash

      LOGFILE="$HOME/.local/share/webapp-usage.log"

      case "''${1:-view}" in
        view|show)
          if [[ -f "$LOGFILE" ]]; then
            ${pkgs.less}/bin/less "$LOGFILE"
          else
            echo "No webapp usage log found at $LOGFILE"
          fi
          ;;
        tail|follow)
          if [[ -f "$LOGFILE" ]]; then
            tail -f "$LOGFILE"
          else
            echo "No webapp usage log found at $LOGFILE"
            echo "Log will be created when webapps are first launched."
            touch "$LOGFILE"
            tail -f "$LOGFILE"
          fi
          ;;
        clear|clean)
          if [[ -f "$LOGFILE" ]]; then
            > "$LOGFILE"
            echo "Webapp usage log cleared"
          else
            echo "No log file to clear"
          fi
          ;;
        stats)
          if [[ -f "$LOGFILE" ]]; then
            echo "Webapp usage statistics:"
            echo "======================="
            grep "Launching.*webapp" "$LOGFILE" | sed 's/.*Launching \(.*\) webapp/\1/' | sort | uniq -c | sort -nr
          else
            echo "No webapp usage log found"
          fi
          ;;
        help|*)
          echo "Webapp Usage Log Viewer"
          echo ""
          echo "Usage: webapp-logs [command]"
          echo ""
          echo "Commands:"
          echo "  view, show    View the full log (default)"
          echo "  tail, follow  Follow the log in real-time"
          echo "  clear, clean  Clear the log file"
          echo "  stats         Show usage statistics"
          echo "  help          Show this help"
          echo ""
          echo "Log location: $LOGFILE"
          ;;
      esac
    '')
  ];

  # Download webapp icons and create desktop entries
  home.file = {
    # Webapp icons
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

    ".local/share/applications/icons/claude.png".source = pkgs.fetchurl {
      url = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/claude-ai.png";
      sha256 = "efa1d055f726a949e2c172810bf1390e2688754311d0ade8556036e87c1275f0";
    };

    # Webapp desktop entries
    ".local/share/applications/chatgpt.desktop".text = ''
      [Desktop Entry]
      Name=ChatGPT
      Comment=ChatGPT Web Application
      Exec=bash -c 'echo "$(date): Launching ChatGPT webapp" >> ~/.local/share/webapp-usage.log; launch-webapp https://chatgpt.com/ --profile=Default'
      Terminal=false
      Type=Application
      Icon=${config.home.homeDirectory}/.local/share/applications/icons/chatgpt.png
      StartupNotify=true
      Categories=Network;WebBrowser;
    '';

    ".local/share/applications/youtube.desktop".text = ''
      [Desktop Entry]
      Name=YouTube
      Comment=YouTube Web Application
      Exec=bash -c 'echo "$(date): Launching YouTube webapp" >> ~/.local/share/webapp-usage.log; launch-webapp https://youtube.com/ --profile=Default'
      Terminal=false
      Type=Application
      Icon=${config.home.homeDirectory}/.local/share/applications/icons/youtube.png
      StartupNotify=true
      Categories=AudioVideo;Network;
    '';

    ".local/share/applications/github.desktop".text = ''
      [Desktop Entry]
      Name=GitHub
      Comment=GitHub Web Application
      Exec=bash -c 'echo "$(date): Launching GitHub webapp" >> ~/.local/share/webapp-usage.log; launch-webapp https://github.com/ --profile=Default'
      Terminal=false
      Type=Application
      Icon=${config.home.homeDirectory}/.local/share/applications/icons/github.png
      StartupNotify=true
      Categories=Development;Network;
    '';

    ".local/share/applications/outlook.desktop".text = ''
      [Desktop Entry]
      Name=Outlook
      Comment=Microsoft Outlook Web Application
      Exec=bash -c 'echo "$(date): Launching Outlook webapp" >> ~/.local/share/webapp-usage.log; launch-webapp https://outlook.office.com/ --profile="Profile 2"'
      Terminal=false
      Type=Application
      Icon=${config.home.homeDirectory}/.local/share/applications/icons/outlook.png
      StartupNotify=true
      Categories=Office;Email;Network;
    '';

    ".local/share/applications/teams.desktop".text = ''
      [Desktop Entry]
      Name=Microsoft Teams
      Comment=Microsoft Teams Web Application
      Exec=bash -c 'echo "$(date): Launching Teams webapp" >> ~/.local/share/webapp-usage.log; launch-webapp https://teams.microsoft.com/ --profile="Profile 2"'
      Terminal=false
      Type=Application
      Icon=${config.home.homeDirectory}/.local/share/applications/icons/teams.png
      StartupNotify=true
      Categories=Office;Network;Chat;
    '';

    ".local/share/applications/claude.desktop".text = ''
      [Desktop Entry]
      Name=Claude Code
      Comment=Claude Code Web Application
      Exec=bash -c 'echo "$(date): Launching Claude Code webapp" >> ~/.local/share/webapp-usage.log; launch-webapp https://claude.ai/ --profile=Default'
      Terminal=false
      Type=Application
      Icon=${config.home.homeDirectory}/.local/share/applications/icons/claude.png
      StartupNotify=true
      Categories=Development;Network;AI;
    '';
  };
}
