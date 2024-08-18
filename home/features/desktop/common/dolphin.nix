{
  pkgs,
  ...
}:

{  home.packages = with pkgs; [
    syncthingtray
  ] ++ (with pkgs.kdePackages; [
    dolphin
    kdegraphics-thumbnailers
    qtimageformats # attempt to fix absence of webp support
    dolphin-plugins
  ]);
}