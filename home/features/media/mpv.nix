{
  pkgs,
  ...
}:

{
  programs = {
    mpv = {
      enable = true;
      defaultProfiles = [ "high-quality" ];
      package = pkgs.mpv.override {
        youtubeSupport = true;
        scripts = (
          with pkgs;
          [
            mpvScripts.mpris
            mpvScripts.autoload
            mpvScripts.uosc
            mpvScripts.thumbfast
            mpvScripts.mpv-notify-send
          ]
        );
      };
    };
  };
}
