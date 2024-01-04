{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    steam
    steam-run
    lunar-client
    lutris
    wineWowPackages.stagingFull

  ];
}