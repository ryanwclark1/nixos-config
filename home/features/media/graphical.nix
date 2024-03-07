{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    digikam
    drawio
    # exif
    exiftool
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
