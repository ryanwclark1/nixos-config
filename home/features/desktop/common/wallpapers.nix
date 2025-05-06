{
  config,
  pkgs,
  ...
}:

let
  wallpapersDir = "${config.home.homeDirectory}/Pictures/wallpapers";
  repoUrl = "https://github.com/ryanwclark1/wallpapers.git";
  syncScript = pkgs.writeShellScriptBin "wallpapers-sync" ''
    #!/usr/bin/env bash

    if [ ! -d "${wallpapersDir}" ]; then
        echo "Wallpapers directory not found. Cloning repository..."
        git clone "${repoUrl}" "${wallpapersDir}"
    else
        echo "Wallpapers directory found. Pulling latest changes..."
        cd "${wallpapersDir}" || exit
        git pull origin main
    fi

    # Set wallpaper using swww
    if command -v swww &> /dev/null; then
        # Ensure swww daemon is running
        if ! pgrep -x "swww-daemon" > /dev/null; then
            swww-daemon &
            sleep 1 # Give it time to start
        fi
        # Set a random wallpaper (change to a specific one if needed)
        swww img "$(find ${wallpapersDir} -type f | shuf -n1)"
    fi
  '';
in
{
  home.packages = with pkgs; [
    git
    swww
    syncScript
  ];

  home.activation.initWallpapers = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "${wallpapersDir}" ]; then
      git clone "${repoUrl}" "${wallpapersDir}"
    fi
  '';

  # Systemd service to run the script
  systemd.user.services.wallpapers-sync = {
    Unit = {
      Description = "Sync Wallpapers from GitHub";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${syncScript}/bin/wallpapers-sync";
    };
    Install = { WantedBy = [ "default.target" ]; };
  };

  # Systemd timer to run the script every 6 hours
  systemd.user.timers.wallpapers-sync = {
    Unit = { Description = "Run Wallpapers Sync every 6 hours"; };
    Timer = {
      OnBootSec = "5m";
      OnUnitActiveSec = "1h";
      Persistent = true;
    };
    Install = { WantedBy = [ "timers.target" ]; };
  };
}
