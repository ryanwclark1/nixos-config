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

  colorscheme = lib.mkDefault colorSchemes.silk-dark;
  specialisation = {
    light.configuration.colorscheme = colorSchemes.silk-light;
  };

  monitors = [
    {
      name = "eDP-1";
      width = 2256;
      height = 1504;
      workspace = "1";
      x = 0;
      primary = true;
    }
  ];

}
