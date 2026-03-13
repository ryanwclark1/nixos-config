#!/usr/bin/env bash

# System menu using rofi - adapted from omarchy-menu for NixOS

# Rofi configuration
ROFI_OPTS="-show-icons -kb-accept-entry Return -kb-cancel Escape"

# Menu function using rofi
menu() {
  local prompt="$1"
  local options="$2"
  local extra="$3"

  read -r -a args <<<"$extra"
  echo -e "$options" | rofi -dmenu -p "$prompt" $ROFI_OPTS "${args[@]}"
}

# Screenshot menu
show_capture_menu() {
  case $(menu "Capture" "📷 Screenshot\n🎬 Screenrecord\n🎨 Color Picker") in
  *Screenshot*) show_screenshot_menu ;;
  *Screenrecord*) show_screenrecord_menu ;;
  *Color*) hyprpicker -a 2>/dev/null || notify-send "Color Picker" "hyprpicker not available" ;;
  *) show_main_menu ;;
  esac
}

# Screenshot submenu
show_screenshot_menu() {
  case $(menu "Screenshot" "📷 Region\n🖼️ Window\n🖥️ Display") in
  *Region*) satty --filename - --fullscreen --output-filename ~/Pictures/Screenshots/satty-$(date '+%Y%m%d_%H%M%S').png < <(hyprshot -m region --raw) 2>/dev/null || notify-send "Screenshot" "Screenshot cancelled" ;;
  *Window*) satty --filename - --fullscreen --output-filename ~/Pictures/Screenshots/satty-$(date '+%Y%m%d_%H%M%S').png < <(hyprshot -m window --raw) 2>/dev/null || notify-send "Screenshot" "Screenshot cancelled" ;;
  *Display*) satty --filename - --fullscreen --output-filename ~/Pictures/Screenshots/satty-$(date '+%Y%m%d_%H%M%S').png < <(hyprshot -m output --raw) 2>/dev/null || notify-send "Screenshot" "Screenshot cancelled" ;;
  *) show_capture_menu ;;
  esac
}

# Screen recording submenu
show_screenrecord_menu() {
  case $(menu "Screenrecord" "🎬 Region\n🖥️ Fullscreen") in
  *Region*) screenrecord region ;;
  *Fullscreen*) screenrecord fullscreen ;;
  *) show_capture_menu ;;
  esac
}

# Audio menu
show_audio_menu() {
  case $(menu "Audio" "🔊 Switch Output\n🔇 Toggle Mute\n🎚️ Volume Mixer") in
  *Switch*) os-audio-switch ;;
  *Mute*) os-audio-volume-mute ;;
  *Mixer*) kitty -e wiremix ;;
  *) show_main_menu ;;
  esac
}

# System settings menu
show_settings_menu() {
  case $(menu "Settings" "🔊 Audio\n📶 Network\n🔵 Bluetooth\n⚡ Power\n🖥️ Displays\n⌨️ Keybindings") in
  *Audio*) show_audio_menu ;;
  *Network*) kitty -e nmtui ;;
  *Bluetooth*) blueman-manager ;;
  *Power*) show_power_menu ;;
  *Displays*) wdisplays ;;
  *Keybindings*) $HYPR_SCRIPTS/hypr/hyprland-keybindings.sh ;;
  *) show_main_menu ;;
  esac
}

# Power menu
show_power_menu() {
  case $(menu "Power" "🔒 Lock\n💤 Suspend\n🔄 Restart\n⏻ Shutdown") in
  *Lock*) hyprlock ;;
  *Suspend*) systemctl suspend ;;
  *Restart*) systemctl reboot ;;
  *Shutdown*) systemctl poweroff ;;
  *) show_settings_menu ;;
  esac
}

# Toggle menu for various system states
show_toggle_menu() {
  case $(menu "Toggle" "🔵 Bluetooth\n📶 WiFi\n🔊 Waybar\n🌙 Night Light") in
  *Bluetooth*)
    if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
      rfkill unblock bluetooth && notify-send "Bluetooth" "Enabled"
    else
      rfkill block bluetooth && notify-send "Bluetooth" "Disabled"
    fi
    ;;
  *WiFi*)
    if rfkill list wifi | grep -q "Soft blocked: yes"; then
      rfkill unblock wifi && notify-send "WiFi" "Enabled"
    else
      rfkill block wifi && notify-send "WiFi" "Disabled"
    fi
    ;;
  *Waybar*)
    if pgrep -x waybar >/dev/null; then
      pkill waybar && notify-send "Waybar" "Hidden"
    else
      waybar & notify-send "Waybar" "Shown"
    fi
    ;;
  *Night*)
    if pgrep -x hyprsunset >/dev/null; then
      pkill hyprsunset && notify-send "Night Light" "Disabled"
    else
      hyprsunset & notify-send "Night Light" "Enabled"
    fi
    ;;
  *) show_main_menu ;;
  esac
}

# Quick utilities menu
show_utilities_menu() {
  case $(menu "Utilities" "📁 File Manager\n💻 Terminal\n📊 System Monitor\n🧮 Calculator\n📝 Text Editor") in
  *File*) nautilus ;;
  *Terminal*) kitty ;;
  *Monitor*) kitty -e btop ;;
  *Calculator*) gnome-calculator ;;
  *Editor*) gnome-text-editor ;;
  *) show_main_menu ;;
  esac
}

# Main menu
show_main_menu() {
  case $(menu "System Menu" "🚀 Apps\n📷 Capture\n⚙️ Settings\n🔀 Toggle\n🛠️ Utilities\n⚡ Power") in
  *Apps*) rofi -show drun -show-icons ;;
  *Capture*) show_capture_menu ;;
  *Settings*) show_settings_menu ;;
  *Toggle*) show_toggle_menu ;;
  *Utilities*) show_utilities_menu ;;
  *Power*) show_power_menu ;;
  esac
}

# Entry point
if [[ -n "$1" ]]; then
  case "${1,,}" in
  apps) rofi -show drun -show-icons ;;
  capture) show_capture_menu ;;
  settings) show_settings_menu ;;
  power) show_power_menu ;;
  toggle) show_toggle_menu ;;
  utilities) show_utilities_menu ;;
  *) show_main_menu ;;
  esac
else
  show_main_menu
fi
