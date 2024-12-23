{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.file.".config/eww/scripts/mem-ad.sh" = {
    text = ''
      #!/bin/sh
      
      total="$(free -m | grep Mem: | awk '{ print $2 }')"
      used="$(free -m | grep Mem: | awk '{ print $3 }')"

      free=$(expr $total - $used)

      if [ "$1" = "total" ]; then
          echo $total
      elif [ "$1" = "used" ]; then
          echo $used
      elif [ "$1" = "free" ]; then
          echo $free
      fi
    '';
    executable = true;
  };
}