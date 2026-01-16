{
  pkgs,
  ...
}:

{
  # Add util-linux and coreutils to system packages to provide mountpoint and timeout commands
  environment.systemPackages = with pkgs; [
    util-linux
    coreutils
  ];

  services.mpd = {
    enable = true; # Re-enabled after fixing autofs configuration
    startWhenNeeded = false;
    user = "mpd";
    group = "audio";
    settings = {
      audio_output = [
        {
          type = "pipewire";
          name = "PipeWire Sound Server";
        }
      ];
      # Mounts to local nfs directory nfs:// did not work
      music_directory = "/mnt/share/music";
      playlist_directory = "/mnt/share/music/playlists";
      db_file = "/var/lib/mpd/tag_cache";
      bind_to_address = "127.0.0.1"; # "any" if you want to allow non-localhost connections
      port = 6600;
    };
  };

  # Ensure MPD waits for autofs and NFS mount to be available
  systemd.services.mpd = {
    after = [
      "autofs.service"
      "network-online.target"
    ];
    wants = [
      "autofs.service"
      "network-online.target"
    ];
    serviceConfig = {
      # Add dependency on autofs but don't fail if it's not ready
      # Wait for the NFS mount to be available before starting
      ExecStartPre = [
        "${pkgs.bash}/bin/bash -c 'systemctl is-active --quiet autofs.service || echo \"autofs not ready, continuing anyway\"'"
        "${pkgs.bash}/bin/bash -c 'for i in {1..30}; do if grep -q /mnt/share /proc/mounts; then break; fi; sleep 1; done'"
        "${pkgs.bash}/bin/bash -c 'for i in {1..30}; do if [ -d /mnt/share/music ]; then break; fi; sleep 1; done'"
      ];
      # Restart if the mount becomes unavailable
      Restart = "always";
      RestartSec = "10";
      # Add timeout to prevent infinite stalling
      TimeoutStartSec = "60";
      TimeoutStopSec = "30";
    };
  };
}
