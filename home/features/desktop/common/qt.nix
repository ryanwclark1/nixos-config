{
  pkgs,
  ...
}:

{
  qt = {
    enable = true;
    platformTheme = "qtct";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  home.packages = with pkgs; [
    adwaita-qt
    adwaita-qt6
  ];
}
