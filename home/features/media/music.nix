{
  pkgs,
  ...
}:

{
  services.mpd = {
    enable = false;
    musicDirectory = ''$HOME/Music'';
  };

  services.fluidsynth = {
    enable = true;
    soundService = "pipewire-pulse";
    extraOptions = [
      "-g 2"
    ];
  };

  programs.ncmpcpp = {
    package = pkgs.ncmpcpp.override { visualizerSupport = true; };
    enable = false;
  };

  home.packages = with pkgs; [
    termusic
    alsa-utils
  ];
}
