#!/usr/bin/env bash

SCREENSHOTS="$HOME/Pictures/Screenshots"
NOW=$(date +%Y-%m-%d_%H-%M-%S)
TARGET="$SCREENSHOTS/$NOW.png"

mkdir -p $SCREENSHOTS

# Parse arguments
MODE="area"  # default
FREEZE=""
WAIT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        screen|window|area)
            MODE="$1"
            shift
            ;;
        --freeze|-f)
            FREEZE="--freeze"
            shift
            ;;
        --wait|-w)
            WAIT="--wait $2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Use grimblast for better screenshot functionality
case "$MODE" in
    "screen")
        grimblast --notify $FREEZE $WAIT copysave screen "$TARGET"
        ;;
    "window")
        grimblast --notify $FREEZE $WAIT copysave active "$TARGET"
        ;;
    *)
        # Default to area selection
        grimblast --notify $FREEZE $WAIT copysave area "$TARGET"
        ;;
esac

# Grimblast already handles notifications, but we can add actions
if [[ -f "$TARGET" ]]; then
    RES=$("notify-send" \
        -a "Screenshot" \
        -i "image-x-generic-symbolic" \
        -h string:image-path:$TARGET \
        -A "file=Show in Files" \
        -A "view=View" \
        -A "edit=Edit" \
        "Screenshot Actions" \
        "What would you like to do?")

    case "$RES" in
        "file") xdg-open "$SCREENSHOTS" ;;
        "view") xdg-open "$TARGET" ;;
        "edit") swappy -f "$TARGET" ;;
        *) ;;
    esac
fi