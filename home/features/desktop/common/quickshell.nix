{ pkgs, ... }:

{
  home.packages = with pkgs; [
    quickshell
    qt6.qtdeclarative # qmlls (QML language server)
    qt6.qtsvg
    qt6.qtimageformats
    qt6.qtmultimedia
    qt6.qt5compat
  ];
}
