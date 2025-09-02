{
  pkgs,
  ...
}:

{
  imports = [
    ./mpris.nix
    ./ncmp.nix
    ./playerctl.nix
    ./scripts.nix  # Audio utility scripts
    # ./spotify.nix
  ];

  home.packages = with pkgs; [
    # termusic # Build issue
    mpc
  ];

}
