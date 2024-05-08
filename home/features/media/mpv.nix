{
  pkgs,
  ...
}:

{
  programs = {
    mpv = {
      enable = true;
      defaultProfiles = [ "high-quality" ];
      scripts = [ pkgs.mpvScripts.mpris ];
    };
  };
}