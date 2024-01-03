# wayland clipboard manager with support for multimedia
# https://github.com/sentriz/cliphist
# requires: go, wl-clipboard, xdg-utils (for image mime inferance)
{
  lib,
  config,
  ...
}:
with lib; {
  options.cliphist.enable = mkEnableOption "cliphist settings";
  config = mkIf config.cliphist.enable {
    services.cliphist = {
      enable = true;
    };
  };
}