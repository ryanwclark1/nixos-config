{
  lib,
  config,
  ...
}:
with lib; {
  options.yt-dlp.enable = mkEnableOption "yt-dlp settings";

  config = mkIf config.yt-dlp.enable {
    programs.yt-dlp = {
      enable = true;
      settings = {
        embed-thumbnail = true;
        embed-subs = true;
        sub-langs = "all";
        downloader = "aria2c";
        downloader-args = "aria2c: '-c -x16 -j16 -s16'";
      };
    };
  };
}