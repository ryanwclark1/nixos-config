
#!/usr/bin/env bash
tmp=/tmp/dunst-history.json

notif() {
export ids=($(dunstctl history | jq '.data[] | .[].id.data'))

printf "\n (box \
    :orientation \"v\" \
    :space-evenly \"false\" \
    :spacing \"20\" \
    :halign \"start\" "

for id in "${ids[@]}"; do
    mapfile -t notif < <(jq -r ".data[] | .[] | select(.id.data == $id) | .appname.data, .icon_path.data, .summary.data, .body.data" "$tmp" | sed -r '/^\s*$/d' | sed -e 's/\%/ percent/g')
    printf "(eventbox :onclick \"dunstctl history-pop $id && dunstctl action 0 && dunstctl close\" \
    (box	\
    :class \"notification\"	\
    :orientation \"h\" \
    :width 300 \
    :space-evenly \"false\" \
    (image \
        :class \"notification-icon\" \
        :path \"${notif[1]}\" \
        :image-height 50 \
        :image-width 100) \
    (box \
        :orientation \"v\" \
        :space-evenly \"false\" \
        :valign \"left\" \
        :width 300 \
        :spacing 10 \
        (label \
            :xalign 0 \
            :wrap "true" \
            :class \"notification-appname\" \
            :text \"${notif[0]}\") \
        (label \
            :xalign 0 \
            :wrap "true" \
            :class \"notification-summary\" \
            :text \"${notif[2]}\") \
        (label \
            :xalign 0 \
            :wrap "true" \
            :class \"notification-body\" \
            :text \"${notif[3]}\"))))"
done
printf ") \n"
}

notif
tail --follow $tmp 2> /dev/null | grep --line-buffered "aa{sv}" | while read -r; do
notif
done