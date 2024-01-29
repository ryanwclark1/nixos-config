{
  inputs,
  outputs,
  pkgs,
  lib,
  ...
}: let
  inherit (inputs.nix-colors) colorSchemes;
in {
  imports = [
    ./global
    ./features/plasma

    ./features/alacritty
    ./features/build
    ./features/cli
    ./features/common-desktop
    ./features/compression
    ./features/development
    ./features/fzf
    ./features/games
    ./features/helix
    ./features/nvim
    ./features/insomnia
    ./features/kitty
    ./features/kubernetes
    ./features/media
    ./features/music
    ./features/networking-utils
    # ./features/pass
    ./features/plasma
    ./features/productivity
    ./features/vscode
    ./features/zellij
    ./features/zoxide

  ];


  colorscheme = lib.mkDefault colorSchemes.nord;
  # specialisation = {
  #   light.configuration.colorscheme = colorSchemes.silk-light;
  # };

}