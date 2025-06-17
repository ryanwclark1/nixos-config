{
  pkgs,
  ...
}:

{
  qt = {
    enable = true;
    platformTheme.name = "kde6";
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
