{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.file.".config/eww/scripts/memory.sh" = {
    text = ''
      #!/bin/sh
      
      printf "%.0f\n" $(free -m | grep Mem | awk '{print ($3/$2)*100}')
    '';
    executable = true;
  };
}

