{
  pkgs,
  ...
}:

{
  home.file.".config/hypr/scripts/task-waybar.sh" = {
    text = ''
      #!/usr/bin/env bash
      sleep 0.1
      ${pkgs.swaynotificationcenter}/bin/swaync-client -t &
    '';
  executable = true;
  };
}

