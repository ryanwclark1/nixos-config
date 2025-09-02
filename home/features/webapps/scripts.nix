{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Web application and browser launcher utilities
  
  home.packages = with pkgs; [
    # Smart browser launcher
    (writeShellScriptBin "launch-browser" ''
      PATH="${pkgs.xdg-utils}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:$PATH"
      
      # Get the default web browser from xdg-settings
      default_browser=$(xdg-settings get default-web-browser 2>/dev/null)
      
      if [[ -n "$default_browser" ]]; then
        # Find the executable from the desktop file
        for app_dir in ~/.local/share/applications ~/.nix-profile/share/applications /run/current-system/sw/share/applications; do
          desktop_file="$app_dir/$default_browser"
          if [[ -f "$desktop_file" ]]; then
            exec_line=$(grep "^Exec=" "$desktop_file" | head -1)
            if [[ -n "$exec_line" ]]; then
              # Extract the executable name (first word after Exec=)
              browser_exec=$(echo "$exec_line" | sed -n 's/^Exec=\([^ ]*\).*/\1/p')
              if [[ -n "$browser_exec" ]]; then
                echo "Launching default browser: $browser_exec"
                exec "$browser_exec" "$@" &
                exit 0
              fi
            fi
          fi
        done
      fi
      
      # Fallback: try common browsers in order of preference
      browsers=(firefox chromium chrome google-chrome-stable brave-browser vivaldi opera)
      
      for browser in "''${browsers[@]}"; do
        if command -v "$browser" >/dev/null 2>&1; then
          echo "Launching fallback browser: $browser"
          exec "$browser" "$@" &
          exit 0
        fi
      done
      
      echo "No web browser found!"
      ${pkgs.libnotify}/bin/notify-send "Browser Error" "No web browser found" -u critical
      exit 1
    '')
    
    # Open URL in default browser
    (writeShellScriptBin "open-url" ''
      if [[ -z "$1" ]]; then
        echo "Usage: open-url <URL>"
        exit 1
      fi
      
      url="$1"
      
      # Add https:// if no protocol specified
      if [[ ! "$url" =~ ^https?:// ]]; then
        url="https://$url"
      fi
      
      echo "Opening: $url"
      launch-browser "$url"
    '')
    
    # Web app launcher with URL validation (simple version to complement existing launch-webapp)
    (writeShellScriptBin "launch-webapp-simple" ''
      if [[ -z "$1" ]]; then
        echo "Usage: launch-webapp-simple <URL> [app-name]"
        exit 1
      fi
      
      url="$1"
      app_name="''${2:-Web App}"
      
      # Add https:// if no protocol specified  
      if [[ ! "$url" =~ ^https?:// ]]; then
        url="https://$url"
      fi
      
      # Launch in app mode if supported browser
      if command -v firefox >/dev/null 2>&1; then
        echo "Launching $app_name in Firefox app mode"
        firefox --new-window --class="$app_name" "$url" &
      elif command -v chromium >/dev/null 2>&1; then
        echo "Launching $app_name in Chromium app mode"
        chromium --app="$url" --class="$app_name" &
      elif command -v google-chrome-stable >/dev/null 2>&1; then
        echo "Launching $app_name in Chrome app mode"
        google-chrome-stable --app="$url" --class="$app_name" &
      else
        echo "Launching $app_name in default browser"
        launch-browser "$url" &
      fi
    '')
    
    # Quick bookmark launcher
    (writeShellScriptBin "launch-bookmarks" ''
      PATH="${pkgs.walker}/bin:$PATH"
      
      # Common bookmarks - customize as needed
      bookmarks=(
        "GitHub|https://github.com"
        "Gmail|https://mail.google.com"
        "Outlook Mail|https://outlook.live.com"
        "Google Calendar|https://calendar.google.com"
        "Outlook Calendar|https://outlook.live.com/calendar"
        "Google Drive|https://drive.google.com"
        "OneDrive|https://onedrive.live.com"
        "YouTube|https://youtube.com"
        "Reddit|https://reddit.com"
        "Twitter|https://twitter.com"
        "NixOS Manual|https://nixos.org/manual/"
        "Home Manager Manual|https://nix-community.github.io/home-manager/"
        "Arch Wiki|https://wiki.archlinux.org/"
      )
      
      # Format for walker menu
      menu_items=""
      for bookmark in "''${bookmarks[@]}"; do
        name="''${bookmark%|*}"
        url="''${bookmark#*|}"
        menu_items+="$name\n"
      done
      
      # Show menu and get selection
      selection=$(echo -e "$menu_items" | walker --dmenu -p "Open bookmark…")
      
      if [[ -n "$selection" ]]; then
        # Find the URL for the selected bookmark
        for bookmark in "''${bookmarks[@]}"; do
          name="''${bookmark%|*}"
          url="''${bookmark#*|}"
          if [[ "$name" == "$selection" ]]; then
            launch-browser "$url"
            break
          fi
        done
      fi
    '')
  ];
}