#!/usr/bin/env bash

# Current Theme
dir="$HOME/.config/rofi/style/"
theme='power-big'
background="$(hyprctl hyprpaper listloaded)"

# CMDs
lastlogin="$(last -n 1 "$USER" | tr -s ' ' | cut -d' ' -f5-7)"
uptime="$(awk -F '( |,)' '{print $6, $7, $8}' <(uptime))"
host="$(hostname)"

# Options
shutdown=' '
reboot=''
lock=''
suspend='󰏦'
logout='󰍃'
yes=' '
no=' '

# Rofi CMD
rofi_cmd() {
  rofi -dmenu \
    -p "Goodbye ${USER}" \
    -mesg "Uptime: $uptime" \
    -theme "${dir}/${theme}.rasi"
}

# Confirmation CMD
confirm_cmd() {
  rofi -dmenu \
    -p 'Confirmation' \
    -mesg 'Are You Sure?' \
    -theme "${dir}/shared/confirm-big.rasi"
}

# Ask for confirmation
confirm_exit() {
  echo -e "$yes\n$no" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
  echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

# Execute Command
run_cmd() {
  selected="$(confirm_exit)"
  if [[ "$selected" == "$yes" ]]; then
    case $1 in
      '--shutdown')
        systemctl poweroff
        ;;
      '--reboot')
        systemctl reboot
        ;;
      '--suspend')
        mpc -q pause
        amixer set Master mute
        systemctl suspend
        ;;
      '--logout')
        case "$DESKTOP_SESSION" in
          hyprland)
            hyprctl dispatch exit
            ;;
          plasma)
            qdbus org.kde.ksmserver /KSMServer logout 0 0 0
            ;;
          *)
            echo "Unsupported session: $DESKTOP_SESSION"
            ;;
        esac
        ;;
    esac
  else
    exit 0
  fi
}

# Actions
chosen="$(run_rofi)"
case ${chosen} in
  $shutdown)
    run_cmd --shutdown
    ;;
  $reboot)
    run_cmd --reboot
    ;;
  $lock)
    if command -v hyprlock &> /dev/null; then
      hyprlock
    else
      echo "hyprlock does not exist."
    fi
    ;;
  $suspend)
    run_cmd --suspend
    ;;
  $logout)
    run_cmd --logout
    ;;
esac