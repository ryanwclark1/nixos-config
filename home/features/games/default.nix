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
    ./steam.nix
  ];
  home = {
    packages = with pkgs; [ gamescope ];
  };
}
