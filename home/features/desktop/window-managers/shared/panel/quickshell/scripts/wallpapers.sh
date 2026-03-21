# wallpapers.sh - List image files under the wallpaper directory as JSON (qs-wallpapers CLI).
# Default matches Config.wallpaperDefaultFolder ($HOME/Pictures). Override with WALLPAPER_DIR.

: "${HOME:=}"
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures}"

if [ -z "$HOME" ] || [ ! -d "$WALLPAPER_DIR" ]; then
    echo "[]"
    exit 0
fi

# path\tmtime lines, then single jq pass (mtime aligns with WallpaperService scan for thumbnail keys).
find "$WALLPAPER_DIR" -maxdepth 2 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    -exec stat -c $'%n\t%Y' {} + 2>/dev/null \
    | jq -R -s '
        split("\n")
        | map(select(length > 0))
        | map(split("\t"))
        | map(select(length >= 2))
        | map({
            name: (.[0] | split("/") | .[-1]),
            path: .[0],
            mtime: (.[1] | tonumber)
          })
      '
