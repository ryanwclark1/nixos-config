
#!/usr/bin/env bash
#define icons for workspaces 1-9
#icontheme=$(geticons -U)
icontheme=$(grep "gtk-icon-theme-name" "$HOME"/.config/gtk-3.0/settings.ini | cut --delimiter="=" -f 2)

workspaces() {
if [[ ${1:0:14} == "activewindow>>" ]]; then #set focused workspace
    string=${1:14}
    class="${string/,*/}"
    export title=${string/,/ \| }
    [[ $title == " | " ]] && unset title
    export iconpath=$(geticons "$class" -s 24 -c 1 -t "$icontheme" | head -n 1)
fi
}

module() {
#output eww widget
echo 	"(box \
                :orientation \"h\" \
                :halign \"start\" \
                :space-evenly false \
                (image \
                    :class \"app-icon\" \
                    :path \"$iconpath\" \
                    :image-width \"36\") \
                (label \
                    :class \"app-name\" \
                    :limit-width \"35\" \
                    :text \"$title\" \
                    :tooltip \"$title\"))"
}

socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/"$HYPRLAND_INSTANCE_SIGNATURE"/.socket2.sock - | while read -r event; do
workspaces "$event"
module
done
