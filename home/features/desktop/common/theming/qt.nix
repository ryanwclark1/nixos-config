{
  pkgs,
  ...
}:

{
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
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
