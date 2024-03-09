{
  pkgs,
  lib,
  ...
}:
let
  sddmTheme = import ./sddm-theme.nix { inherit pkgs; };
in
{

  services = {
    xserver = {
      enable = true;
      displayManager = {
        defaultSession = "plasma";
        sddm = {
          enable = true;
          wayland.enable = true;
          theme = "breeze";
        };
      };
    };
  };
}