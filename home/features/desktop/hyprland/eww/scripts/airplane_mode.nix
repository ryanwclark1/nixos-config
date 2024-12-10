{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.file.".config/eww/scripts/airplane_mode.sh" = {
    text = ''
      #!/bin/sh
      status=$(nmcli n)
      if [[ "$status" == "enabled" ]]; then
          nmcli n off
      else
          nmcli n on
      fi
		'';
		executable = true;
	};
}

