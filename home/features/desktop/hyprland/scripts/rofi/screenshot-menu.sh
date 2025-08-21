#!/usr/bin/env bash

# Rofi Screenshot Menu
# Provides a rofi interface for different screenshot options

# Icons for screenshot options
AREA_ICON="󰩭"      # Selection area icon
SCREEN_ICON="󰹑"    # Full screen icon  
WINDOW_ICON="󰖲"    # Window icon
CLIPBOARD_ICON="󰅌" # Clipboard icon
OCR_ICON="󰗊"       # OCR/text recognition icon
RECORD_AREA_ICON="󰑋" # Record area icon
RECORD_SCREEN_ICON="󰕧" # Record screen icon
STOP_RECORD_ICON="󰓛"   # Stop recording icon

# Check if recording is active
RECORDING_PID_FILE="/tmp/wf-recorder.pid"
if [ -f "$RECORDING_PID_FILE" ] && kill -0 "$(cat "$RECORDING_PID_FILE")" 2>/dev/null; then
    RECORDING_ACTIVE=true
else
    RECORDING_ACTIVE=false
fi

# Menu options with icons
if [ "$RECORDING_ACTIVE" = true ]; then
    options=(
        "$STOP_RECORD_ICON  Stop Recording"
        "$AREA_ICON  Select Area"
        "$SCREEN_ICON  Full Screen" 
        "$WINDOW_ICON  Active Window"
        "$CLIPBOARD_ICON  Area to Clipboard"
        "$OCR_ICON  OCR Area (Copy Text)"
    )
else
    options=(
        "$AREA_ICON  Select Area"
        "$SCREEN_ICON  Full Screen" 
        "$WINDOW_ICON  Active Window"
        "$CLIPBOARD_ICON  Area to Clipboard"
        "$OCR_ICON  OCR Area (Copy Text)"
        "$RECORD_AREA_ICON  Record Area"
        "$RECORD_SCREEN_ICON  Record Screen"
    )
fi

# Show rofi menu - adjust lines based on options count
LINES_COUNT=${#options[@]}
choice=$(printf '%s\n' "${options[@]}" | rofi -dmenu -i -p "Screenshot/Record" -theme-str "listview { lines: $LINES_COUNT; }")

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
    "$RECORD_AREA_ICON  Record Area")
        # Record selected area
        RECORDING_DIR="$HOME/Videos/recordings"
        mkdir -p "$RECORDING_DIR"
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        OUTPUT_FILE="$RECORDING_DIR/recording_area_$TIMESTAMP.mp4"
        
        notify-send -t 2000 "Screen Recording" "Select area to record..."
        geometry=$(slurp)
        if [ -n "$geometry" ]; then
            wf-recorder -g "$geometry" -f "$OUTPUT_FILE" &
            echo $! > "$RECORDING_PID_FILE"
            notify-send -t 3000 "Screen Recording" "Recording area started\nOutput: $OUTPUT_FILE"
        fi
        ;;
    "$RECORD_SCREEN_ICON  Record Screen")
        # Record full screen
        RECORDING_DIR="$HOME/Videos/recordings"
        mkdir -p "$RECORDING_DIR"
        TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
        OUTPUT_FILE="$RECORDING_DIR/recording_screen_$TIMESTAMP.mp4"
        
        wf-recorder -f "$OUTPUT_FILE" &
        echo $! > "$RECORDING_PID_FILE"
        notify-send -t 3000 "Screen Recording" "Full screen recording started\nOutput: $OUTPUT_FILE"
        ;;
    "$STOP_RECORD_ICON  Stop Recording")
        # Stop recording
        if [ -f "$RECORDING_PID_FILE" ]; then
            PID=$(cat "$RECORDING_PID_FILE")
            if kill -0 "$PID" 2>/dev/null; then
                kill -INT "$PID"
                rm -f "$RECORDING_PID_FILE"
                notify-send -t 3000 "Screen Recording" "Recording stopped and saved"
            else
                rm -f "$RECORDING_PID_FILE"
                notify-send -t 3000 "Screen Recording" "No active recording found"
            fi
        else
            notify-send -t 3000 "Screen Recording" "No active recording found"
        fi
        ;;
    *)
        # If nothing selected or ESC pressed, exit
        exit 0
        ;;
esac