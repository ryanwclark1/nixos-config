{
  pkgs,
  ...
}:

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