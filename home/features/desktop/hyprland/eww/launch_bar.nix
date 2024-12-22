{
  config,
  lib,
  pkgs,
  ...
}:
let
    opacity = lib.toHexString (((builtins.ceil (config.stylix.opacity.popups * 100)) * 255) / 100);
    EWW_BIN = lib.getExe config.programs.eww.package;
    EWW = "${EWW_BIN} -c ${config.home.homeDirectory}/.config/eww";

in
{
  home.file.".config/eww/launch_bar.sh" = {
    text = ''
      #!/usr/bin/env bash

      ## Files and cmd
      FILE="$HOME/.cache/eww_launch.xyz"
      EWW="$HOME/.local/bin/eww/eww -c $HOME/.config/eww"
      EWW=${EWW}

      ## Run eww daemon if not running already
      if [[ ! `pidof eww` ]]; then
        $EWW daemon
        sleep 1
      fi

      ## Open widgets
      run_eww() {
        $EWW open-many \
              searchapps \
              musicplayer \
              network \
              appbar \
              bg \
              calendar \
              quicksettings \
              bigpowermenu \
              fetch \
              quote \
              favorites \
              smalldate \
              notes \
              sys \
              screenshot
      }

      ## Launch or close widgets accordingly
      if [[ ! -f "$FILE" ]]; then
        touch "$FILE"
        run_eww
        # && bspc config -m LVDS-1 top_padding 49
      else
        $EWW close-all && pkill eww
        rm "$FILE"
      fi

    '';
    executable = true;
  };
}