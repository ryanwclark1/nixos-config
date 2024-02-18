{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    devpod
    devpod-desktop
  ];
}
