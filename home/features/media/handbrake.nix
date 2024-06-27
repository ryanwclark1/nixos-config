# A tool for converting video files and ripping DVDs.
{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    handbrake
  ];
}
