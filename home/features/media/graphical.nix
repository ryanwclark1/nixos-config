{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    digikam
    drawio
    exif
    gimp
    graphviz
    krita
    imagemagick
    imv
    inkscape
    pastel
    vhs
    viu
  ];
}