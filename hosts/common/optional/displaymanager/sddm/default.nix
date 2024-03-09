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
      enable = lib.mkDefault true;
      displayManager = {
        defaultSession = "plasma";
        sddm = {
          enable = true;
          wayland.enable = true;
          theme = "${sddmTheme}";
        };
      };
    };
  };
  environment.systemPackages = with pkgs; [
    libsForQt5.qt5.qtquickcontrols2
    # Is this qtgraphicaleffects functionaility in QT Quick for QT6?
    libsForQt5.qt5.qtgraphicaleffects
  ];
}