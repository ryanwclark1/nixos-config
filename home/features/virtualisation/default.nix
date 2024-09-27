{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    gnome-boxes
  ];
}