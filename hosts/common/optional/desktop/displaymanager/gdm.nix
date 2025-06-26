{
  lib,
  ...
}:

{
  services = {
    xserver = {
      enable = lib.mkDefault true;
      xkb.layout = "us";
      displayManager = {
        gdm = {
          enable = true;
          wayland = true;
        };
      };
    };
  };
}