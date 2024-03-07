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
    ./features/desktop/hyprland
    ./features/desktop/plasma
    ./features/desktop/common

    ./features/alacritty
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
    ./features/lf
    ./features/media
    ./features/networking-utils
    ./features/nvim
    ./features/productivity
    ./features/qutebrowser
    ./features/shell
    ./features/starship
    ./features/sys-stats
    ./features/vscode
    ./features/wezterm
    ./features/zellij
    ./features/zoxide
  ];

  colorscheme = lib.mkDefault colorSchemes.nord;
  specialisation = {
    light.configuration.colorscheme = colorSchemes.silk-light;
  };

}
