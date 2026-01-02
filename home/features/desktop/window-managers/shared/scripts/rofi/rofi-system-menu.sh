#!/usr/bin/env bash

# System Menu for Hyprland using rofi
# Comprehensive menu system with nested submenus

# Rofi configuration
ROFI_OPTS="-show-icons -kb-accept-entry Return -kb-cancel Escape"

# Nerd Font Icons
ICON_APPS="󰨞"           # Applications
ICON_CAPTURE="󰄀"        # Capture/Screenshot
ICON_SETTINGS="󰒓"       # Settings
ICON_TOGGLE="󰕧"         # Toggle
ICON_UTILITIES="󰓓"      # Utilities
ICON_WINDOWS="󰖲"        # Windows
ICON_POWER="󰁹"          # Power
ICON_SCREENSHOT="󰄀"     # Screenshot
ICON_SCREENRECORD="󰨳"   # Screen record
ICON_COLOR="󰏘"          # Color picker
ICON_REGION="󰆞"         # Region
ICON_WINDOW="󰖲"         # Window
ICON_DISPLAY="󰍹"        # Display
ICON_FOLDER="󰉋"         # Folder
ICON_AUDIO="󰕾"          # Audio
ICON_AUDIO_SWITCH="󰍽"   # Audio switch
ICON_MUTE="󰝞"           # Mute
ICON_VOL_DOWN="󰕿"       # Volume down
ICON_VOL_UP="󰕾"         # Volume up
ICON_MIXER="󰓃"          # Mixer
ICON_NETWORK="󰖩"        # Network/WiFi
ICON_BLUETOOTH="󰂯"      # Bluetooth
ICON_GLOBE="󰤨"          # Globe/Internet
ICON_DISPLAYS="󰍹"       # Displays
ICON_KEYBOARD="󰌌"       # Keyboard
ICON_APPEARANCE="󰃟"     # Appearance
ICON_LOCK="󰌾"           # Lock screen
ICON_SUSPEND="󰤄"        # Suspend
ICON_RESTART="󰑓"        # Restart
ICON_SHUTDOWN="󰐥"       # Shutdown
ICON_LOGOUT="󰗽"         # Logout
ICON_YES="󰄬"            # Yes/Check
ICON_NO="󰅖"             # No/Cross
ICON_ENABLED="󰄲"        # Enabled/Green
ICON_DISABLED="󰄱"       # Disabled/Red
ICON_VISIBLE="󰄲"        # Visible
ICON_HIDDEN="󰄱"         # Hidden
ICON_ACTIVE="󰄲"         # Active
ICON_FILE_MANAGER="󰉋"   # File manager
ICON_TERMINAL="󰆍"       # Terminal
ICON_MONITOR="󰓓"        # System monitor
ICON_CALCULATOR="󰃬"     # Calculator
ICON_EDITOR="󰈙"         # Text editor
ICON_CLIPBOARD="󰅌"      # Clipboard
ICON_WINDOW_INFO="󰋼"    # Window info
ICON_CLOSE="󰅖"          # Close
ICON_RESIZE="󰍸"         # Resize
ICON_FOCUS="󰋼"          # Focus
ICON_WORKSPACE="󰨞"      # Workspace

# Confirmation dialog
confirm_action() {
  local title="$1"
  local message="$2"

  local confirm_options=(
    "$ICON_YES  Yes"
    "$ICON_NO  No"
  )
  selection=$(printf '%s\n' "${confirm_options[@]}" | rofi -dmenu -i -p "$title" $ROFI_OPTS)
  [[ "$selection" == *"Yes"* ]]
}

# Screenshot menu
show_capture_menu() {
  local capture_options=(
    "$ICON_SCREENSHOT  Screenshot"
    "$ICON_SCREENRECORD  Screenrecord"
    "$ICON_COLOR  Color Picker"
  )
  selection=$(printf '%s\n' "${capture_options[@]}" | rofi -dmenu -i -p "$ICON_CAPTURE Capture" $ROFI_OPTS)

  case "$selection" in
    *Screenshot*) show_screenshot_menu ;;
    *Screenrecord*) show_screenrecord_menu ;;
    *Color*)
      if command -v hyprpicker >/dev/null; then
        hyprpicker -a 2>/dev/null || notify-send "Color Picker" "hyprpicker failed"
      else
        notify-send "Color Picker" "hyprpicker not available"
      fi
      ;;
    *) [[ -n "$selection" ]] && show_main_menu ;;
  esac
}

# Screenshot submenu
show_screenshot_menu() {
  local screenshot_options=(
    "$ICON_REGION  Region"
    "$ICON_WINDOW  Window"
    "$ICON_DISPLAY  Display"
    "$ICON_FOLDER  Open Folder"
  )
  selection=$(printf '%s\n' "${screenshot_options[@]}" | rofi -dmenu -i -p "$ICON_SCREENSHOT Screenshot" $ROFI_OPTS)

  case "$selection" in
    *Region*)
      if command -v screenshot-enhanced >/dev/null; then
        screenshot-enhanced region
      else
        notify-send "Screenshot" "screenshot-enhanced not available"
      fi
      ;;
    *Window*)
      if command -v screenshot-enhanced >/dev/null; then
        screenshot-enhanced window
      else
        notify-send "Screenshot" "screenshot-enhanced not available"
      fi
      ;;
    *Display*)
      if command -v screenshot-enhanced >/dev/null; then
        screenshot-enhanced output
      else
        notify-send "Screenshot" "screenshot-enhanced not available"
      fi
      ;;
    *Folder*)
      if command -v screenshots-folder >/dev/null; then
        screenshots-folder
      else
        notify-send "Screenshot" "screenshots-folder not available"
      fi
      ;;
    *) [[ -n "$selection" ]] && show_capture_menu ;;
  esac
}

# Screen recording submenu
show_screenrecord_menu() {
  local screenrecord_options=(
    "$ICON_REGION  Region"
    "$ICON_DISPLAY  Fullscreen"
    "$ICON_CLOSE  Stop Recording"
  )
  selection=$(printf '%s\n' "${screenrecord_options[@]}" | rofi -dmenu -i -p "$ICON_SCREENRECORD Screenrecord" $ROFI_OPTS)

  case "$selection" in
    *Region*)
      if command -v screenrecord >/dev/null; then
        screenrecord region
      else
        notify-send "Screenrecord" "screenrecord not available"
      fi
      ;;
    *Fullscreen*)
      if command -v screenrecord >/dev/null; then
        screenrecord fullscreen
      else
        notify-send "Screenrecord" "screenrecord not available"
      fi
      ;;
    *Stop*)
      if command -v screenrecord-stop >/dev/null; then
        screenrecord-stop
      else
        notify-send "Screenrecord" "screenrecord-stop not available"
      fi
      ;;
    *) [[ -n "$selection" ]] && show_capture_menu ;;
  esac
}

# Audio menu
show_audio_menu() {
  local audio_options=(
    "$ICON_AUDIO_SWITCH  Switch Output"
    "$ICON_MUTE  Toggle Mute"
    "$ICON_VOL_DOWN  Volume Down"
    "$ICON_VOL_UP  Volume Up"
    "$ICON_MIXER  Mixer"
  )
  selection=$(printf '%s\n' "${audio_options[@]}" | rofi -dmenu -i -p "$ICON_AUDIO Audio" $ROFI_OPTS)

  case "$selection" in
    *Switch*)
      if command -v audio-switch >/dev/null; then
        audio-switch
      else
        notify-send "Audio" "audio-switch not available"
      fi
      ;;
    *Mute*)
      if command -v audio-volume-mute >/dev/null; then
        audio-volume-mute
      else
        notify-send "Audio" "audio-volume-mute not available"
      fi
      ;;
    *Down*)
      if command -v audio-volume-down >/dev/null; then
        audio-volume-down
      else
        notify-send "Audio" "audio-volume-down not available"
      fi
      ;;
    *Up*)
      if command -v audio-volume-up >/dev/null; then
        audio-volume-up
      else
        notify-send "Audio" "audio-volume-up not available"
      fi
      ;;
    *Mixer*)
      if command -v wiremix >/dev/null; then
        kitty -e wiremix &
      elif command -v pwvucontrol >/dev/null; then
        pwvucontrol &
      else
        notify-send "Audio" "No mixer available"
      fi
      ;;
    *) [[ -n "$selection" ]] && show_main_menu ;;
  esac
}

# Network menu
show_network_menu() {
  local network_options=(
    "$ICON_NETWORK  WiFi Manager"
    "$ICON_BLUETOOTH  Bluetooth"
    "$ICON_GLOBE  Network Settings"
  )
  selection=$(printf '%s\n' "${network_options[@]}" | rofi -dmenu -i -p "$ICON_NETWORK Network" $ROFI_OPTS)

  case "$selection" in
    *WiFi*)
      if command -v nmtui >/dev/null; then
        kitty -e nmtui &
      elif command -v nm-connection-editor >/dev/null; then
        nm-connection-editor &
      else
        notify-send "Network" "No network manager available"
      fi
      ;;
    *Bluetooth*)
      if command -v blueberry >/dev/null; then
        blueberry &
      elif command -v blueman-manager >/dev/null; then
        blueman-manager &
      else
        notify-send "Bluetooth" "No bluetooth manager available"
      fi
      ;;
    *Settings*)
      if command -v gnome-control-center >/dev/null; then
        gnome-control-center network 2>/dev/null || show_network_menu
      else
        show_network_menu
      fi
      ;;
    *) [[ -n "$selection" ]] && show_settings_menu ;;
  esac
}

# System settings menu
show_settings_menu() {
  local settings_options=(
    "$ICON_AUDIO  Audio"
    "$ICON_NETWORK  Network"
    "$ICON_BLUETOOTH  Bluetooth"
    "$ICON_POWER  Power"
    "$ICON_DISPLAYS  Displays"
    "$ICON_KEYBOARD  Keybindings"
    "$ICON_APPEARANCE  Appearance"
  )
  selection=$(printf '%s\n' "${settings_options[@]}" | rofi -dmenu -i -p "$ICON_SETTINGS Settings" $ROFI_OPTS)

  case "$selection" in
    *Audio*) show_audio_menu ;;
    *Network*) show_network_menu ;;
    *Bluetooth*)
      if command -v blueberry >/dev/null; then
        blueberry &
      elif command -v blueman-manager >/dev/null; then
        blueman-manager &
      else
        notify-send "Bluetooth" "No bluetooth manager available"
      fi
      ;;
    *Power*) show_power_menu ;;
    *Displays*)
      if command -v wdisplays >/dev/null; then
        wdisplays &
      elif command -v arandr >/dev/null; then
        arandr &
      else
        notify-send "Displays" "No display configuration tool found"
      fi
      ;;
    *Keybindings*)
      if [[ -n "$HYPR_SCRIPTS" ]] && [[ -f "$HYPR_SCRIPTS/hyprland-keybindings.sh" ]]; then
        "$HYPR_SCRIPTS/hyprland-keybindings.sh"
      else
        notify-send "Keybindings" "Keybindings script not found"
      fi
      ;;
    *Appearance*)
      if command -v gnome-control-center >/dev/null; then
        gnome-control-center appearance 2>/dev/null || notify-send "Settings" "Appearance settings not available"
      elif command -v lxappearance >/dev/null; then
        lxappearance &
      elif command -v qt5ct >/dev/null; then
        qt5ct &
      elif command -v qt6ct >/dev/null; then
        qt6ct &
      else
        notify-send "Settings" "No theme manager found"
      fi
      ;;
    *) [[ -n "$selection" ]] && show_main_menu ;;
  esac
}

# Power menu with confirmation
show_power_menu() {
  local power_options=(
    "$ICON_LOCK  Lock Screen"
    "$ICON_SUSPEND  Suspend"
    "$ICON_RESTART  Restart"
    "$ICON_SHUTDOWN  Shutdown"
    "$ICON_LOGOUT  Log Out"
  )
  selection=$(printf '%s\n' "${power_options[@]}" | rofi -dmenu -i -p "$ICON_POWER Power" $ROFI_OPTS)

  case "$selection" in
    *Lock*)
      if command -v hyprlock >/dev/null; then
        hyprlock
      else
        notify-send "Lock" "hyprlock not available"
      fi
      ;;
    *Suspend*)
      if confirm_action "$ICON_SUSPEND Suspend" "Suspend system?"; then
        systemctl suspend
      else
        show_power_menu
      fi
      ;;
    *Restart*)
      if confirm_action "$ICON_RESTART Restart" "Restart system?"; then
        systemctl reboot
      else
        show_power_menu
      fi
      ;;
    *Shutdown*)
      if confirm_action "$ICON_SHUTDOWN Shutdown" "Shutdown system?"; then
        systemctl poweroff
      else
        show_power_menu
      fi
      ;;
    *Log*)
      if confirm_action "$ICON_LOGOUT Log Out" "Log out of session?"; then
        if command -v hyprctl >/dev/null; then
          hyprctl dispatch exit
        else
          notify-send "Logout" "hyprctl not available"
        fi
      else
        show_power_menu
      fi
      ;;
    *) [[ -n "$selection" ]] && show_main_menu ;;
  esac
}

# Toggle menu for various system states
show_toggle_menu() {
  # Get current states for display
  bluetooth_status="$ICON_DISABLED Disabled"
  wifi_status="$ICON_DISABLED Disabled"
  waybar_status="$ICON_HIDDEN Hidden"
  nightlight_status="$ICON_DISABLED Disabled"

  if command -v rfkill >/dev/null; then
    if ! rfkill list bluetooth 2>/dev/null | grep -q "Soft blocked: yes"; then
      bluetooth_status="$ICON_ENABLED Enabled"
    fi

    if ! rfkill list wifi 2>/dev/null | grep -q "Soft blocked: yes"; then
      wifi_status="$ICON_ENABLED Enabled"
    fi
  fi

  if pgrep -x waybar >/dev/null 2>&1; then
    waybar_status="$ICON_VISIBLE Visible"
  fi

  if pgrep -x hyprsunset >/dev/null 2>&1; then
    nightlight_status="$ICON_ACTIVE Active"
  fi

  local toggle_options=(
    "$ICON_BLUETOOTH  Bluetooth ($bluetooth_status)"
    "$ICON_NETWORK  WiFi ($wifi_status)"
    "$ICON_MONITOR  Waybar ($waybar_status)"
    "󰖨  Night Light ($nightlight_status)"
  )
  selection=$(printf '%s\n' "${toggle_options[@]}" | rofi -dmenu -i -p "$ICON_TOGGLE Toggle" $ROFI_OPTS)

  case "$selection" in
    *Bluetooth*)
      if command -v rfkill >/dev/null; then
        if rfkill list bluetooth 2>/dev/null | grep -q "Soft blocked: yes"; then
          rfkill unblock bluetooth && notify-send "$ICON_BLUETOOTH Bluetooth" "Enabled" -t 2000
        else
          rfkill block bluetooth && notify-send "$ICON_BLUETOOTH Bluetooth" "Disabled" -t 2000
        fi
        show_toggle_menu  # Return to toggle menu to see updated status
      else
        notify-send "Bluetooth" "rfkill not available"
      fi
      ;;
    *WiFi*)
      if command -v rfkill >/dev/null; then
        if rfkill list wifi 2>/dev/null | grep -q "Soft blocked: yes"; then
          rfkill unblock wifi && notify-send "$ICON_NETWORK WiFi" "Enabled" -t 2000
        else
          rfkill block wifi && notify-send "$ICON_NETWORK WiFi" "Disabled" -t 2000
        fi
        show_toggle_menu
      else
        notify-send "WiFi" "rfkill not available"
      fi
      ;;
    *Waybar*)
      if pgrep -x waybar >/dev/null 2>&1; then
        pkill waybar && notify-send "$ICON_MONITOR Waybar" "Hidden" -t 2000
      else
        waybar & notify-send "$ICON_MONITOR Waybar" "Shown" -t 2000
      fi
      show_toggle_menu
      ;;
    *Night*)
      if pgrep -x hyprsunset >/dev/null 2>&1; then
        pkill hyprsunset && notify-send "󰖨 Night Light" "Disabled" -t 2000
      else
        hyprsunset & notify-send "󰖨 Night Light" "Enabled" -t 2000
      fi
      show_toggle_menu
      ;;
    *) [[ -n "$selection" ]] && show_main_menu ;;
  esac
}

# Quick utilities menu
show_utilities_menu() {
  local utilities_options=(
    "$ICON_FILE_MANAGER  File Manager"
    "$ICON_TERMINAL  Terminal"
    "$ICON_MONITOR  System Monitor"
    "$ICON_CALCULATOR  Calculator"
    "$ICON_EDITOR  Text Editor"
    "$ICON_COLOR  Color Picker"
    "$ICON_CLIPBOARD  Clipboard History"
  )
  selection=$(printf '%s\n' "${utilities_options[@]}" | rofi -dmenu -i -p "$ICON_UTILITIES Utilities" $ROFI_OPTS)

  case "$selection" in
    *File*)
      if command -v nautilus >/dev/null; then
        nautilus &
      elif command -v thunar >/dev/null; then
        thunar &
      elif command -v dolphin >/dev/null; then
        dolphin &
      else
        notify-send "File Manager" "No file manager found"
      fi
      ;;
    *Terminal*)
      if command -v kitty >/dev/null; then
        kitty &
      elif command -v alacritty >/dev/null; then
        alacritty &
      else
        notify-send "Terminal" "No terminal found"
      fi
      ;;
    *Monitor*)
      if command -v btop >/dev/null; then
        kitty -e btop &
      elif command -v htop >/dev/null; then
        kitty -e htop &
      else
        notify-send "Monitor" "No system monitor found"
      fi
      ;;
    *Calculator*)
      if command -v gnome-calculator >/dev/null; then
        gnome-calculator &
      elif command -v qalculate-gtk >/dev/null; then
        qalculate-gtk &
      else
        notify-send "Calculator" "No calculator found"
      fi
      ;;
    *Editor*)
      if command -v gnome-text-editor >/dev/null; then
        gnome-text-editor &
      elif command -v gedit >/dev/null; then
        gedit &
      elif command -v mousepad >/dev/null; then
        mousepad &
      else
        notify-send "Editor" "No text editor found"
      fi
      ;;
    *Color*)
      if command -v hyprpicker >/dev/null; then
        hyprpicker -a 2>/dev/null || notify-send "Color Picker" "hyprpicker failed"
      else
        notify-send "Color Picker" "hyprpicker not available"
      fi
      ;;
    *Clipboard*)
      if command -v greenclip >/dev/null; then
        rofi -modi "clipboard:greenclip print" -show clipboard -show-icons &
      else
        notify-send "Clipboard" "greenclip not available"
      fi
      ;;
    *) [[ -n "$selection" ]] && show_main_menu ;;
  esac
}

# Window management menu
show_windows_menu() {
  local windows_options=(
    "$ICON_WINDOW_INFO  Window Info"
    "$ICON_CLOSE  Close All Windows"
    "$ICON_RESIZE  Resize Mode"
    "$ICON_FOCUS  Focus Mode"
    "$ICON_WORKSPACE  Workspace Switch"
  )
  selection=$(printf '%s\n' "${windows_options[@]}" | rofi -dmenu -i -p "$ICON_WINDOWS Windows" $ROFI_OPTS)

  case "$selection" in
    *Info*)
      if command -v window-info >/dev/null; then
        window-info | rofi -dmenu -p "Window Info" $ROFI_OPTS
      else
        notify-send "Window Info" "window-info not available"
      fi
      ;;
    *Close*)
      if confirm_action "$ICON_CLOSE Close All" "Close all windows?"; then
        if command -v close-all-windows >/dev/null; then
          close-all-windows
        else
          notify-send "Windows" "close-all-windows not available"
        fi
      else
        show_windows_menu
      fi
      ;;
    *Resize*) notify-send "$ICON_WINDOWS Resize Mode" "Use SUPER + mouse to resize windows" -t 3000 ;;
    *Focus*) notify-send "$ICON_WINDOWS Focus Mode" "Use Alt+Tab to cycle through windows" -t 3000 ;;
    *Workspace*)
      local workspace_options=(
        "1"
        "2"
        "3"
        "4"
        "5"
        "6"
        "7"
        "8"
        "9"
      )
      workspace=$(printf '%s\n' "${workspace_options[@]}" | rofi -dmenu -i -p "$ICON_WORKSPACE Switch Workspace" $ROFI_OPTS)
      if [[ -n "$workspace" ]] && command -v workspace-switch >/dev/null; then
        workspace-switch "$workspace"
      elif [[ -n "$workspace" ]] && command -v hyprctl >/dev/null; then
        hyprctl dispatch workspace "$workspace"
      fi
      ;;
    *) [[ -n "$selection" ]] && show_main_menu ;;
  esac
}

# Main menu
show_main_menu() {
  local main_options=(
    "$ICON_APPS  Apps"
    "$ICON_CAPTURE  Capture"
    "$ICON_SETTINGS  Settings"
    "$ICON_TOGGLE  Toggle"
    "$ICON_UTILITIES  Utilities"
    "$ICON_WINDOWS  Windows"
    "$ICON_POWER  Power"
  )
  selection=$(printf '%s\n' "${main_options[@]}" | rofi -dmenu -i -p "󰀄 System Menu" $ROFI_OPTS)

  case "$selection" in
    *Apps*) rofi -show drun -show-icons ;;
    *Capture*) show_capture_menu ;;
    *Settings*) show_settings_menu ;;
    *Toggle*) show_toggle_menu ;;
    *Utilities*) show_utilities_menu ;;
    *Windows*) show_windows_menu ;;
    *Power*) show_power_menu ;;
    *) exit 0 ;;
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
    windows) show_windows_menu ;;
    *) show_main_menu ;;
  esac
else
  show_main_menu
fi
