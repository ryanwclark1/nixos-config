{
  pkgs,
  ...
}:
{
  imports = [
    ./dolphin.nix
    # ./factorio.nix
    ./heroic.nix
    ./lutris.nix
    ./prism-launcher.nix
    ./steam.nix

  ];
  home = {
    packages = with pkgs; [ gamescope ];
  };
}
