{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.file.".config/eww/launch_bar.sh" = {
    text = ''
      #!/usr/bin/env bash

      ## Files and cmd
      FILE="~/.cache/eww_launch.xyz"
      EWW="eww -c ${config.home.homeDirectory}/.config/eww"

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