{
  pkgs,
  ...
}:

{
  programs.freetube = {
    enable = true;
    package = pkgs.freetube;
    settings = {
      allowDashAv1Formats = true;
      checkForUpdates     = false;
      defaultQuality      = "1080";
    };
  };
}