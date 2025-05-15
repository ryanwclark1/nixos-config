{
  lib,
  pkgs,
  ...
}:
let
  # sddmTheme = "breeze";
  sddmTheme = import ./sddm-theme.nix { inherit pkgs; };
in
{


  services = {
    displayManager = {
      defaultSession = lib.mkDefault "hyprland-uwsm";
      sddm = {
        enable = true;
        wayland.enable = true;
        autoNumlock = true;
        enableHidpi = true;
        extraPackages = [
          sddmTheme
          # sddm
          # sddm-greeter
          # sddm-theme
        ];
        # theme "= "${sddmTheme}";
        theme = "sddm-astronaut-theme";
      };
    };
  };
}
