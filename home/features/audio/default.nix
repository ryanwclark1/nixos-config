{
  pkgs,
  ...
}:

{
  imports = [
    ./mpris.nix
    ./playerctl.nix
    ./spotify.nix
  ];

  home.packages = with pkgs; [
    termusic # Build issue
    mpc
  ];

}
