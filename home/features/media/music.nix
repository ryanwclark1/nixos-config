{ pkgs
, ...
}:
# TODO: Use path variable
{
  services.mpd = {
    enable = false;
    musicDirectory = ''$HOME/Music'';
    # network.startWhenNeeded = true;
    network.port = 6601;
  };

  programs.ncmpcpp = {
    package = pkgs.ncmpcpp.override { visualizerSupport = true; };
    enable = false;
  };

  home.packages = with pkgs; [
    termusic
    alsa-utils
  ];

  services.fluidsynth = {
    enable = true;
    soundService = "pipewire-pulse";
    extraOptions = [
      "-g 2"
    ];
  };

}
