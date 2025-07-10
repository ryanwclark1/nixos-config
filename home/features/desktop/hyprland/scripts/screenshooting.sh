#!/usr/bin/env bash

SCREENSHOTS="$HOME/Pictures/Screenshots"
NOW=$(date +%Y-%m-%d_%H-%M-%S)
TARGET="$SCREENSHOTS/$NOW.png"

mkdir -p $SCREENSHOTS

# Use grimblast for better screenshot functionality
if [[ "$1" == "screen" ]]; then
    grimblast --notify copysave screen "$TARGET"
elif [[ "$1" == "window" ]]; then
    grimblast --notify copysave active "$TARGET"
else
    # Default to area selection
    grimblast --notify copysave area "$TARGET"
fi

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