{
  config,
  lib,
  ...
}:
with lib;

{
  imports = [
    ./gnomeconfig.nix
  ];

  options.gnome.enable = mkEnableOption "gnome settings";
  config = mkIf config.gnome.enable {
    gnomeconfig.enable = true;

    services.xserver = {
      enable = true;
      layout = "us";
      displayManager = {
        gdm = {
          enable = true;
          # Would likely create issue if used on laptop.
          autoSuspend = false;
          wayland = true;
        };
      };
      desktopManager = {
        gnome = {
          enable = true;
          # List of packages for which gsettings are overridden. list of paths
          extraGSettingsOverridePackages = [];
          # Additional gsettings overrides. strings concatenated with "\n"
          extraGSettingsOverrides = "";
        };
      };
    };

    # Temp, find better place.  Allows for copy/paste between host and guest.
    services.spice-vdagentd.enable = true;
  };
}