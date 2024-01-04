{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
with lib; {
  options.nnn.enable = mkEnableOption "nnn settings";

  config = mkIf config.nnn.enable {
    programs.nnn = {
      enable = true;
      package = pkgs.nnn.override {withNerdIcons = true;};
      bookmarks = {
        d = "~/Downloads";
        p = "~/Documents/projects";
        g = "~/Videos/golearn/";
      };
      extraPackages = with pkgs; [
        ffmpegthumbnailer
        mediainfo
      ];
      plugins = {
        src = inputs.nnn-plugins + "/plugins";
      };
    };
  };
}
