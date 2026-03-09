#!/usr/bin/env bash
# wallpapers.sh - List all wallpapers in the wallpapers directory

WALLPAPER_DIR="$HOME/Pictures/wallpapers"

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "[]"
    exit 0
fi

# Use jq to build the final JSON array
# Filter for image files
find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | while read -r file; do
    name=$(basename "$file")
    name_esc=$(echo "$name" | jq -R .)
    path_esc=$(echo "$file" | jq -R .)
    echo "{\"name\":$name_esc,\"path\":$path_esc}"
done | jq -s '.'
