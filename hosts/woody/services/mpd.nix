{
  ...
}:

{
  services.mpd = {
    enable = true;
    startWhenNeeded = true;
    musicDirectory = "nfs://10.10.100.210:/mnt/tank/share/music";
    playlistDirectory = "nfs://10.10.100.210:/mnt/tank/share/music/playlists";
    dbFile = "/var/lib/mpd/tag_cache";
    user = "mpd";
    group = "audio";
    network = {
      listenAddress = "127.0.0.1"; # "any" if you want to allow non-localhost connections
      port = 6600;
    };
  };
}
