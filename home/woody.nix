{
  inputs,
  lib,
  ...
}:
let
  inherit (inputs.nix-colors) colorSchemes;
in
{
  imports = [
    ./global
    ./features/desktop/gnome
    ./features/desktop/common

    ./features/alacritty
    ./features/build
    ./features/cli
    ./features/compression
    ./features/development
    ./features/eza
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
    ./features/shell
    ./features/starship
    ./features/sys-stats
    ./features/vscode
    ./features/zellij
    ./features/zoxide
  ];

  colorscheme = lib.mkDefault colorSchemes.nord;
  specialisation = {
    light.configuration.colorscheme = colorSchemes.silk-light;
  };

}
