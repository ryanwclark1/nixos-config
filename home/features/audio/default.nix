{
  pkgs,
  ...
}:

{
  imports = [
    ./mpris.nix
    ./ncmp.nix
    ./playerctl.nix
    ./spotify.nix
  ];

  home.packages = with pkgs; [
    # termusic # Build issue
    mpc
  ];
}
