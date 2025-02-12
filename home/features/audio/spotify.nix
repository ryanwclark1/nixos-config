{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [
    spotify
  ];

  services.spotifyd = {
    enable = true;
    package = pkgs.spotifyd.override {withMpris = true;};
    settings.global = {
      autoplay = true;
      backend = "pulseaudio";
      bitrate = 320;
      cache_path = "${config.xdg.cacheHome}/spotifyd";
      device_type = "computer";
      initial_volume = "100";
      # password_cmd = "tail -1 /run/secrets-for-users/spotify";
      use_mpris = true;
      # username_cmd = "head -1 /run/secrets-for-users/spotify";
      volume_normalisation = false;
    };
  };
}