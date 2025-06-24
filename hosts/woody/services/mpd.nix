{
  pkgs,
  ...
}:

{
  # Add util-linux to system packages to provide mountpoint command
  environment.systemPackages = with pkgs; [
    util-linux
  ];

  services.mpd = {
    enable = true; # Re-enabled after fixing autofs configuration
    startWhenNeeded = false;
    musicDirectory = "/mnt/share/music"; # Mounts to local nfs directory nfs:// did not work
    playlistDirectory = "/mnt/share/music/playlists";
    dbFile = "/var/lib/mpd/tag_cache";
    user = "mpd";
    group = "audio";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire Sound Server"
      }
    '';
    network = {
      listenAddress = "127.0.0.1"; # "any" if you want to allow non-localhost connections
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
        "/bin/sh -c 'systemctl is-active --quiet autofs.service || echo \"autofs not ready, continuing anyway\"'"
        "/bin/sh -c 'timeout 30 sh -c \"until grep -q /mnt/share /proc/mounts; do sleep 1; done\"'"
        "/bin/sh -c 'timeout 30 sh -c \"until [ -d /mnt/share/music ]; do sleep 1; done\"'"
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
