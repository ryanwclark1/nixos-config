{
  config,
  pkgs,
  ...
}:

{
  services.mpdris2 = {
    enabled = true;
    package = pkgs.mpdris2;
    multimediaKeys = true;
    notifications = true;
    mpd = {
      host = config.services.mpd.network.listenAddress;
      musicDirectory = config.services.mpd.musicDirectory;
      port = config.services.mpd.network.port;
    }
  };
}