{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    sublime-music
  ];
}
