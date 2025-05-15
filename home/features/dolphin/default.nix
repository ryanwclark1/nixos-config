{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    syncthingtray
  ] ++ (with pkgs.kdePackages; [
    dolphin
    kio-extras 
    kdegraphics-thumbnailers
    qtimageformats # attempt to fix absence of webp support
    dolphin-plugins
  ]);
}
