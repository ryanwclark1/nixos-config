{ inputs, outputs, lib, ... }: let
  inherit (inputs.nix-colors) colorSchemes;
in {
  imports = [
    ./global
    ./features/desktop/wireless
    ./features/desktop/hyprland
    ./features/pass
    ./features/productivity
  ];

  # colorscheme = lib.mkDefault colorSchemes.silk-dark;
  # specialisation = {
  #   light.configuration.colorscheme = colorSchemes.silk-light;
  # };
}
