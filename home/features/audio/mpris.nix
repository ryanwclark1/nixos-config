{
  pkgs,
  ...
}:

{
  services.mpdris2 = {
    enable = true;
    package = pkgs.mpdris2;
    multimediaKeys = true;
    notifications = true;
    mpd = {
      host = "127.0.0.1"; # "any" if you want to allow non-localhost connections
      port = 6600;
      musicDirectory = "/mnt/share/music";
      # config doesn't work as service is not home-manager service
      # host = config.services.mpd.network.listenAddress;
      # musicDirectory = config.services.mpd.musicDirectory;
      # port = config.services.mpd.network.port;
    };
  };
}