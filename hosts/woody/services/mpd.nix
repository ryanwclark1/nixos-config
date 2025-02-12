{
  pkgs,
  ...
}:

{
  services.mpd = {
    enable = true;
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



}
