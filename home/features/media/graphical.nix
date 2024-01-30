{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    exif
    gimp
    graphviz
    krita
    imagemagick
    imv
    inkscape
    pastel
    rx
    vhs
    viu
  ];

}