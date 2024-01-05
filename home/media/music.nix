{
  config,
  lib,
  pkgs,
  ...
}:
# TODO: Use path variable
with lib; {
  options.music.enable = mkEnableOption "music settings";

  config = mkIf config.music.enable {
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
  };
}