{
  pkgs,
  ...
}:

{
  imports = [
    ./cava.nix
    ./mpris.nix
    ./ncmp.nix
    ./playerctl.nix
    ./spotify.nix
  ];

  home.packages = with pkgs; [
    termusic
    mpc
  ];
}
