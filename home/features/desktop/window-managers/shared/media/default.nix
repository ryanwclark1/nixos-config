{
  pkgs,
  ...
}:

{
  imports = [
    ./satty
    ./waypaper
  ];

  home.packages = with pkgs; [
    wiremix
  ];
}
