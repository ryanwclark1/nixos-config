{
  pkgs,
  ...
}:

{
  imports = [
    ./swappy.nix
    ./swayosd
    ./waypaper
  ];

  home.packages = with pkgs; [
    wiremix
  ];
}
