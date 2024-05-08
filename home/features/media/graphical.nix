{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    digikam
    drawio
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
