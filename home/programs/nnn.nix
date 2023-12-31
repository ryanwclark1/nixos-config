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
        # p = "~/Documents/projects";
        # g = "~/Videos/golearn/";
      };
      extraPackages = with pkgs; [
        # ffmpegthumbnailer
        mediainfo
      ];
      plugins = {
        src = inputs.nnn-plugins + "/plugins";
      };
    };
  };
}


# { config, pkgs, ... }:
# let
#   # NNN colours - catppuccin
#   # https://github.com/catppuccin/catppuccin/discussions/1955#discussion-4904597
#   BLK = "03";
#   CHR = "03";
#   DIR = "04";
#   EXE = "02";
#   REG = "07";
#   HARDLINK = "05";
#   SYMLINK = "05";
#   MISSING = "08";
#   ORPHAN = "01";
#   FIFO = "06";
#   SOCK = "03";
#   UNKNOWN="01";
# in
# {

#   environment.shellInit = ''
#     source ${pkgs.nnn-scripts}/bin/nnn-script.sh
#   '';

#   environment.systemPackages = with pkgs; [
#     (nnn.override { withNerdIcons = true; })
#   ];

#   environment.sessionVariables = {
#     # https://github.com/catppuccin/catppuccin/discussions/1955#discussion-4904597
#     NNN_COLORS = "#04020301;4231";
#     NNN_FCOLORS = "${BLK}${CHR}${DIR}${EXE}${REG}${HARDLINK}${SYMLINK}${MISSING}${ORPHAN}${FIFO}${SOCK}${UNKNOWN}";
# #    NNN_ICONLOOKUP = if config.setup.gui.enable == true then "1" else "0";
#     NNN_FIFO = "/tmp/nnn.fifo";
#   };

# }
