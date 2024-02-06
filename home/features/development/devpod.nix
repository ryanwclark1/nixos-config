{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    devpod-desktop
  ];
}