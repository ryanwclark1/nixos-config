{
  pkgs,
  ...
}:

{
  programs = {
    mpv = {
      enable = true;
      defaultProfiles = [ "high-quality" ];
      package = pkgs.mpv-unwrapped.wrapper {
        mpv = pkgs.mpv-unwrapped;
        youtubeSupport = true;
        scripts =
          (with pkgs; [
            mpvScripts.mpris
            mpvScripts.autoload
            mpvScripts.uosc
            mpvScripts.thumbfast
            mpvScripts.mpv-notify-send
          ]);
      };
    };
  };
}