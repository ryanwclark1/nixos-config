{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    gnome-boxes
    # VM viewers (moved from desktop/common)
    virt-viewer # Remote VM viewer
  ];
}