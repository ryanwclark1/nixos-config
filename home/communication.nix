{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  options.telegram.enable = mkEnableOption "telegram settings";
  options.discord.enable = mkEnableOption "discord settings";

  config = {
    home.packages = with pkgs;
      mkIf config.telegram.enable [
        tdesktop
      ]
      + mkIf config.discord.enable [
        discord
        discordo
      ];
  };
}