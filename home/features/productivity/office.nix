{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    libreoffice-fresh
    # libreoffice-qt6
  ];
}
