{
  pkgs,
  ...
}:

{
  qt = {
    enable = true;
    platformTheme = "gtk";
    style = {
      name = "gtk2";
      package = pkgs.kdePackages.qt6gtk2;
    };
  };
}
