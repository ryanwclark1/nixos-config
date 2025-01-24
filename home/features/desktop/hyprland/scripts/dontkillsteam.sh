
#!/usr/bin/env bash

if [[ $(hyprctl activewindow -j | jq -r ".class") == "Steam" ]]; then
    ydotool windowunmap $(ydotool getactivewindow)
else
    hyprctl dispatch killactive ""
fi