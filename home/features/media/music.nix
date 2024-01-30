{
  config,
  lib,
  pkgs,
  ...
}:
# TODO: Use path variable
{
  services.mpd = {
    enable = false;
    musicDirectory = /home/administrator/Music;
    # network.startWhenNeeded = true;
    network.port = 6601;
  };

  programs.ncmpcpp = {
    package = pkgs.ncmpcpp.override {visualizerSupport = true;};
    enable = false;
  };

  home.packages = with pkgs; [
    termusic
  ];
}