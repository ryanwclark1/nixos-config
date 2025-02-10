{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    waypaper
  ];

  home.file."waypaper/config.ini" = {
    source = ./config.ini;
  };
}