
#!/usr/bin/env bash

status=$(nmcli g | grep -oE "disconnected")
essid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
# essid=$(nmcli c | grep wlp2s0 | awk '{print ($1)}')

if [ $status ] ; then
    icon="󰖩"
    text=""
    col="#575268"

else
    icon="󰖪"
    text="$essid"
    col="#a1bdce"
fi

if [[ "$1" == "--COL" ]]; then
    echo $col
elif [[ "$1" == "--ESSID" ]]; then
  echo $text
elif [[ "$1" == "--ICON" ]]; then
  echo $icon
fi
