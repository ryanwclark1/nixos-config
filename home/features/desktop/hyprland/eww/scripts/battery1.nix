{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.file.".config/eww/scripts/battery1.sh" = {
    text = ''
		#!/usr/bin/env bash
		battery() {
			BAT=`ls /sys/class/power_supply | grep BAT | head -n 1`
			cat /sys/class/power_supply/$BAT/capacity
		}
		battery_stat() {
			BAT=`ls /sys/class/power_supply | grep BAT | head -n 1`
			cat /sys/class/power_supply/$BAT/status
		}

		if [[ "$1" == "--bat" ]]; then
			battery
		elif [[ "$1" == "--bat-st" ]]; then
			battery_stat
		fi
		'';
		executable = true;
	};
}

