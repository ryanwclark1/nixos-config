#!/usr/bin/env bash

BAT=`ls /sys/class/power_supply | grep BAT | head -n 1`

battery() {
	cat /sys/class/power_supply/$BAT/capacity
}

battery_stat() {
	cat /sys/class/power_supply/$BAT/status
}

if [[ "$1" == "--bat" ]]; then
	battery
elif [[ "$1" == "--bat-st" ]]; then
	battery_stat
fi

