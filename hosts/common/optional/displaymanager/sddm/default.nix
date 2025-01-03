{
  lib,
  ...
}:
let
  sddmTheme = "breeze";
  # sddmTheme = import ./sddm-theme.nix { inherit pkgs; };
in
{

  services = {
    xserver = {
      enable = lib.mkDefault true;
    };
    displayManager = {
      defaultSession = "plasma";
      sddm = {
        enable = true;
        wayland.enable = true;
        theme = "${sddmTheme}";
      };
    };
  };
}