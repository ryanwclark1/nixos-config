{ inputs, outputs, pkgs, lib, ... }: let
  inherit (inputs.nix-colors) colorSchemes;
in {
  imports = [
    ./global
    ./features/plasma/plasmaconfig.nix
    # ./features/desktop/wireless
    # ./features/desktop/hyprland
    ./features/alacritty
    ./features/build
    ./features/cli
    ./features/development
    ./features/fzf
    ./features/games
    ./features/helix
    ./features/nvim
    ./features/insomnia
    ./features/kitty
    ./features/media
    ./features/networking-utils
    # ./features/pass
    ./features/plasma
    ./features/productivity
    ./features/vscode
    ./features/zellij
    ./features/zoxide
    ./features/kubernetes

  ];


  colorscheme = lib.mkDefault colorSchemes.silk-dark;
  specialisation = {
    light.configuration.colorscheme = colorSchemes.silk-light;
  };

}