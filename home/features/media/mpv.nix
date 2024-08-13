{
  pkgs,
  ...
}:

{
  programs = {
    mpv = {
      enable = true;
      defaultProfiles = [ "high-quality" ];
      package = pkgs.wrapMpv (pkgs.mpv-unwrapped.override { vapoursynthSupport = true; }) { youtubeSupport = true; };
      scripts = with pkgs; [
        mpvScripts.mpris
        mpvScripts.thumbnail
      ];
    };
  };
}