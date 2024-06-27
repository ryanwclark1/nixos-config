# Cross-platform media player and streaming server.
{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    vlc
  ];
}
