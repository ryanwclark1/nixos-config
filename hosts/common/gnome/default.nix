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
      # Enable the Plasma Desktop Environment.
      displayManager = {
        gdm = {
          enable = true;
          # This is turned on because gnome is used on desktop.
          # Would likely create issue if used on laptop.
          autoSuspend = false;
          # banner = ''
          #   Welcome Ryan!
          #   '';
          wayland = true;
        };
      };
      desktopManager = {
        # https://github.com/NixOS/nixpkgs/blob/592047fc9e4f7b74a4dc85d1b9f5243dfe4899e3/nixos/modules/services/x11/desktop-managers/gnome.nix
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