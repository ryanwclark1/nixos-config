#!/usr/bin/env bash

# Rofi Screenshot Menu
# Provides a rofi interface for different screenshot options

# Icons for screenshot options
AREA_ICON="󰩭"      # Selection area icon
SCREEN_ICON="󰹑"    # Full screen icon  
WINDOW_ICON="󰖲"    # Window icon
CLIPBOARD_ICON="󰅌" # Clipboard icon
OCR_ICON="󰗊"       # OCR/text recognition icon

# Menu options with icons
options=(
    "$AREA_ICON  Select Area"
    "$SCREEN_ICON  Full Screen" 
    "$WINDOW_ICON  Active Window"
    "$CLIPBOARD_ICON  Area to Clipboard"
    "$OCR_ICON  OCR Area (Copy Text)"
)

# Show rofi menu
choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -i -p "Screenshot" -theme-str 'listview { lines: 5; }')

# Get the script directory
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
SCREENSHOT_SCRIPT="$SCRIPT_DIR/../screenshooting.sh"

# Execute based on choice
case "$choice" in
    "$AREA_ICON  Select Area")
        exec "$SCREENSHOT_SCRIPT" area
        ;;
    "$SCREEN_ICON  Full Screen")
        exec "$SCREENSHOT_SCRIPT" screen
        ;;
    "$WINDOW_ICON  Active Window")
        exec "$SCREENSHOT_SCRIPT" window
        ;;
    "$CLIPBOARD_ICON  Area to Clipboard")
        # Take area screenshot and copy to clipboard only (don't save)
        grimblast --notify copy area
        ;;
    "$OCR_ICON  OCR Area (Copy Text)")
        # OCR functionality - extract text from selected area
        grimblast --freeze save area - | tesseract - - | wl-copy && notify-send -t 3000 "OCR" "Text copied to clipboard"
        ;;
    *)
        # If nothing selected or ESC pressed, exit
        exit 0
        ;;
esac