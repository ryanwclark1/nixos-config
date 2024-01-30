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
    ./features/desktop/gnome

    ./features/alacritty
    ./features/build
    ./features/cli
    ./features/common-desktop
    ./features/compression
    ./features/development
    ./features/filesearch
    ./features/fzf
    ./features/games
    ./features/helix
    ./features/insomnia
    ./features/kitty
    ./features/kubernetes
    ./features/media
    ./features/networking-utils
    ./features/nvim
    # ./features/pass
    ./features/productivity
    ./features/starship
    ./features/vscode
    ./features/zellij
    ./features/zoxide
  ];

  colorscheme = lib.mkDefault colorSchemes.nord;
  specialisation = {
    light.configuration.colorscheme = colorSchemes.silk-light;
  };

}