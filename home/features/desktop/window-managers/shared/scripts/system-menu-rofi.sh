#!/usr/bin/env bash

# System menu using rofi - alternative to walker-based system menu

# Rofi theme and configuration
ROFI_THEME="android_notification"
ROFI_OPTS="-theme $ROFI_THEME -show-icons -kb-accept-entry Return -kb-cancel Escape"

# Menu function using rofi
menu() {
  local prompt="$1"
  local options="$2"
  local extra_opts="$3"
  
  echo -e "$options" | rofi -dmenu -p "$prompt" $ROFI_OPTS $extra_opts
}

# Screenshot menu
show_capture_menu() {
  selection=$(menu "📷 Capture" "📷 Screenshot\n🎬 Screenrecord\n🎨 Color Picker")
  
  case "$selection" in
  *Screenshot*) show_screenshot_menu ;;
  *Screenrecord*) show_screenrecord_menu ;;
  *Color*) hyprpicker -a 2>/dev/null || notify-send "Color Picker" "hyprpicker not available" ;;
  *) [[ -n "$selection" ]] && show_main_menu ;;
  esac
}

# Screenshot submenu
show_screenshot_menu() {
  selection=$(menu "📷 Screenshot" "📷 Region\n🖼️ Window\n🖥️ Display\n📁 Open Folder")
  
  case "$selection" in
  *Region*) screenshot-enhanced region ;;
  *Window*) screenshot-enhanced window ;;
  *Display*) screenshot-enhanced output ;;
  *Folder*) screenshots-folder ;;
  *) [[ -n "$selection" ]] && show_capture_menu ;;
  esac
}

# Screen recording submenu  
show_screenrecord_menu() {
  selection=$(menu "🎬 Screenrecord" "🎬 Region\n🖥️ Fullscreen\n⏹️ Stop Recording")
  
  case "$selection" in
  *Region*) screenrecord region ;;
  *Fullscreen*) screenrecord fullscreen ;;
  *Stop*) screenrecord-stop ;;
  *) [[ -n "$selection" ]] && show_capture_menu ;;
  esac
}

# Audio menu
show_audio_menu() {
  selection=$(menu "🔊 Audio" "🔊 Switch Output\n🔇 Toggle Mute\n🔉 Volume Down\n🔊 Volume Up\n🎚️ Mixer")
  
  case "$selection" in
  *Switch*) audio-switch ;;
  *Mute*) audio-volume-mute ;;
  *Down*) audio-volume-down ;;
  *Up*) audio-volume-up ;;
  *Mixer*) kitty -e wiremix ;;
  *) [[ -n "$selection" ]] && show_main_menu ;;
  esac
}

# Network menu
show_network_menu() {
  selection=$(menu "📶 Network" "📶 WiFi Manager\n🔵 Bluetooth\n🌐 Network Settings")
  
  case "$selection" in
  *WiFi*) kitty -e nmtui ;;
  *Bluetooth*) blueberry ;;
  *Settings*) gnome-control-center network 2>/dev/null || show_network_menu ;;
  *) [[ -n "$selection" ]] && show_settings_menu ;;
  esac
}

# System settings menu
show_settings_menu() {
  selection=$(menu "⚙️ Settings" "🔊 Audio\n📶 Network\n🔵 Bluetooth\n⚡ Power\n🖥️ Displays\n⌨️ Keybindings\n🎨 Appearance")
  
  case "$selection" in
  *Audio*) show_audio_menu ;;
  *Network*) show_network_menu ;;
  *Bluetooth*) blueberry ;;
  *Power*) show_power_menu ;;
  *Displays*) wdisplays ;;
  *Keybindings*) $HYPR_SCRIPTS/hyprland-keybindings.sh ;;
  *Appearance*) gnome-control-center appearance 2>/dev/null || notify-send "Settings" "Appearance settings not available" ;;
  *) [[ -n "$selection" ]] && show_main_menu ;;
  esac
}

# Power menu with confirmation
show_power_menu() {
  selection=$(menu "⚡ Power" "🔒 Lock Screen\n💤 Suspend\n🔄 Restart\n⏻ Shutdown\n🏠 Log Out")
  
  case "$selection" in
  *Lock*) hyprlock ;;
  *Suspend*) 
    if confirm_action "💤 Suspend" "Suspend system?"; then
      systemctl suspend
    else
      show_power_menu
    fi
    ;;
  *Restart*) 
    if confirm_action "🔄 Restart" "Restart system?"; then
      systemctl reboot
    else
      show_power_menu
    fi
    ;;
  *Shutdown*) 
    if confirm_action "⏻ Shutdown" "Shutdown system?"; then
      systemctl poweroff
    else
      show_power_menu
    fi
    ;;
  *Log*) 
    if confirm_action "🏠 Log Out" "Log out of session?"; then
      hyprctl dispatch exit
    else
      show_power_menu
    fi
    ;;
  *) [[ -n "$selection" ]] && show_main_menu ;;
  esac
}

# Confirmation dialog
confirm_action() {
  local title="$1"
  local message="$2"
  
  selection=$(menu "$title" "✅ Yes\n❌ No" "-theme android_notification")
  [[ "$selection" == *"Yes"* ]]
}

# Toggle menu for various system states
show_toggle_menu() {
  # Get current states for display
  bluetooth_status="🔴 Disabled"
  wifi_status="🔴 Disabled"
  waybar_status="🔴 Hidden"
  nightlight_status="🔴 Disabled"
  
  if ! rfkill list bluetooth | grep -q "Soft blocked: yes"; then
    bluetooth_status="🟢 Enabled"
  fi
  
  if ! rfkill list wifi | grep -q "Soft blocked: yes"; then
    wifi_status="🟢 Enabled"
  fi
  
  if pgrep -x waybar >/dev/null; then
    waybar_status="🟢 Visible"
  fi
  
  if pgrep -x hyprsunset >/dev/null; then
    nightlight_status="🟢 Active"
  fi
  
  selection=$(menu "🔀 Toggle" "🔵 Bluetooth ($bluetooth_status)\n📶 WiFi ($wifi_status)\n📊 Waybar ($waybar_status)\n🌙 Night Light ($nightlight_status)")
  
  case "$selection" in
  *Bluetooth*) 
    if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
      rfkill unblock bluetooth && notify-send "🔵 Bluetooth" "Enabled" -t 2000
    else
      rfkill block bluetooth && notify-send "🔵 Bluetooth" "Disabled" -t 2000
    fi
    show_toggle_menu  # Return to toggle menu to see updated status
    ;;
  *WiFi*)
    if rfkill list wifi | grep -q "Soft blocked: yes"; then
      rfkill unblock wifi && notify-send "📶 WiFi" "Enabled" -t 2000
    else
      rfkill block wifi && notify-send "📶 WiFi" "Disabled" -t 2000
    fi
    show_toggle_menu
    ;;
  *Waybar*)
    if pgrep -x waybar >/dev/null; then
      pkill waybar && notify-send "📊 Waybar" "Hidden" -t 2000
    else  
      waybar & notify-send "📊 Waybar" "Shown" -t 2000
    fi
    show_toggle_menu
    ;;
  *Night*)
    if pgrep -x hyprsunset >/dev/null; then
      pkill hyprsunset && notify-send "🌙 Night Light" "Disabled" -t 2000
    else
      hyprsunset & notify-send "🌙 Night Light" "Enabled" -t 2000
    fi
    show_toggle_menu
    ;;
  *) [[ -n "$selection" ]] && show_main_menu ;;
  esac
}

# Quick utilities menu
show_utilities_menu() {
  selection=$(menu "🛠️ Utilities" "📁 File Manager\n💻 Terminal\n📊 System Monitor\n🧮 Calculator\n📝 Text Editor\n🎨 Color Picker\n📋 Clipboard History")
  
  case "$selection" in
  *File*) nautilus ;;
  *Terminal*) kitty ;;
  *Monitor*) kitty -e btop ;;
  *Calculator*) gnome-calculator ;;
  *Editor*) gnome-text-editor ;;
  *Color*) hyprpicker -a ;;
  *Clipboard*) rofi -modi "clipboard:greenclip print" -show clipboard -theme android_notification ;;
  *) [[ -n "$selection" ]] && show_main_menu ;;
  esac
}

# Window management menu
show_windows_menu() {
  selection=$(menu "🪟 Windows" "🔍 Window Info\n❌ Close All Windows\n📐 Resize Mode\n🎯 Focus Mode\n🔄 Workspace Switch")
  
  case "$selection" in
  *Info*) window-info | rofi -dmenu -p "Window Info" $ROFI_OPTS ;;
  *Close*) 
    if confirm_action "❌ Close All" "Close all windows?"; then
      close-all-windows
    else
      show_windows_menu
    fi
    ;;
  *Resize*) notify-send "🪟 Resize Mode" "Use SUPER + mouse to resize windows" -t 3000 ;;
  *Focus*) notify-send "🪟 Focus Mode" "Use Alt+Tab to cycle through windows" -t 3000 ;;
  *Workspace*) 
    workspace=$(menu "🔄 Switch Workspace" "1\n2\n3\n4\n5\n6\n7\n8\n9")
    [[ -n "$workspace" ]] && workspace-switch "$workspace"
    ;;
  *) [[ -n "$selection" ]] && show_main_menu ;;
  esac
}

# Main menu
show_main_menu() {
  selection=$(menu "🚀 System Menu" "🚀 Apps\n📷 Capture\n⚙️ Settings\n🔀 Toggle\n🛠️ Utilities\n🪟 Windows\n⚡ Power")
  
  case "$selection" in
  *Apps*) rofi -show drun -theme $ROFI_THEME -show-icons ;;
  *Capture*) show_capture_menu ;;
  *Settings*) show_settings_menu ;;  
  *Toggle*) show_toggle_menu ;;
  *Utilities*) show_utilities_menu ;;
  *Windows*) show_windows_menu ;;
  *Power*) show_power_menu ;;
  esac
}

# Entry point
if [[ -n "$1" ]]; then
  case "${1,,}" in
  apps) rofi -show drun -theme $ROFI_THEME -show-icons ;;
  capture) show_capture_menu ;;
  settings) show_settings_menu ;;
  power) show_power_menu ;;
  toggle) show_toggle_menu ;;
  utilities) show_utilities_menu ;;
  windows) show_windows_menu ;;
  *) show_main_menu ;;
  esac
else
  show_main_menu
fi