#!/usr/bin/env bash
#  _   _           _       _                 _     _
# | | | |_ __   __| | __ _| |_ ___   ___  __| | __| |_ __ ___
# | | | | '_ \ / _` |/ _` | __/ _ \ / __|/ _` |/ _` | '_ ` _ \
# | |_| | |_) | (_| | (_| | ||  __/ \__ \ (_| | (_| | | | | | |
#  \___/| .__/ \__,_|\__,_|\__\___| |___/\__,_|\__,_|_| |_| |_|
#       |_|
#

set -euo pipefail

# Configuration
CACHE_FILE="$HOME/.config/desktop/window-managers/hyprland/scripts/cache/current_wallpaper"
SDDM_THEME_NAME="sequoia"
SDDM_ASSET_FOLDER="/usr/share/sddm/themes/$SDDM_THEME_NAME/backgrounds"
SDDM_THEME_TPL="/usr/share/ml4w-hyprland/sddm/theme.conf"
CUSTOM_THEME_TPL="$HOME/.config/desktop/window-managers/hyprland/scripts/settings/sddm/theme.conf"
SDDM_CONF_SOURCE="/usr/share/ml4w-hyprland/sddm/sddm.conf"
SDDM_CONF_DEST="/etc/sddm.conf.d/sddm.conf"

# Check required commands
if ! command -v sudo >/dev/null 2>&1; then
    echo "Error: sudo not found" >&2
    exit 1
fi

# Check if running as root (not recommended, but handle it)
if [[ $EUID -eq 0 ]]; then
    SUDO_CMD=""
else
    SUDO_CMD="sudo"
fi

# Helper functions
log() {
    echo ":: $1"
}

error() {
    echo "Error: $1" >&2
    exit 1
}

# Check if gum is available (optional)
if command -v gum >/dev/null 2>&1; then
    USE_GUM=true
else
    USE_GUM=false
fi

# Main execution
sleep 1
clear

# Display header
if command -v figlet >/dev/null 2>&1; then
    echo -e "${GREEN:-}"
    figlet -f smslant "SDDM Wallpaper" 2>/dev/null || echo "SDDM Wallpaper"
    echo -e "${NONE:-}"
else
    echo "=== SDDM Wallpaper ==="
fi

# Check cache file
if [[ ! -f "$CACHE_FILE" ]]; then
    error "Cache file not found: $CACHE_FILE"
fi

# Read current wallpaper
current_wallpaper=$(cat "$CACHE_FILE")
if [[ -z "$current_wallpaper" ]]; then
    error "Cache file is empty"
fi

# Get extension
extension="${current_wallpaper##*.}"

# Check if wallpaper file exists
if [[ ! -f "$current_wallpaper" ]]; then
    if [[ "$USE_GUM" == true ]]; then
        gum spin --spinner dot --title "File $current_wallpaper does not exist" -- sleep 3
    else
        error "Wallpaper file does not exist: $current_wallpaper"
    fi
    exit 1
fi

log "Set the current wallpaper $current_wallpaper as SDDM wallpaper."
echo

# Use custom theme template if available
if [[ -f "$CUSTOM_THEME_TPL" ]]; then
    SDDM_THEME_TPL="$CUSTOM_THEME_TPL"
    log "Using custom theme.conf"
fi

# Create SDDM config directory
if [[ ! -d /etc/sddm.conf.d/ ]]; then
    $SUDO_CMD mkdir -p /etc/sddm.conf.d
    log "Folder /etc/sddm.conf.d created."
fi

# Copy SDDM config
if [[ -f "$SDDM_CONF_SOURCE" ]]; then
    $SUDO_CMD cp "$SDDM_CONF_SOURCE" "$SDDM_CONF_DEST"
    log "File $SDDM_CONF_DEST updated."
else
    error "SDDM config source not found: $SDDM_CONF_SOURCE"
fi

# Ensure asset folder exists
$SUDO_CMD mkdir -p "$SDDM_ASSET_FOLDER"

# Copy wallpaper to asset folder
$SUDO_CMD cp "$current_wallpaper" "$SDDM_ASSET_FOLDER/current_wallpaper.$extension"
log "Current wallpaper copied into $SDDM_ASSET_FOLDER"

# Copy and update theme config
if [[ -f "$SDDM_THEME_TPL" ]]; then
    $SUDO_CMD cp "$SDDM_THEME_TPL" "/usr/share/sddm/themes/$SDDM_THEME_NAME/"
    $SUDO_CMD sed -i "s/CURRENTWALLPAPER/current_wallpaper.$extension/" "/usr/share/sddm/themes/$SDDM_THEME_NAME/theme.conf"
    log "File theme.conf updated in /usr/share/sddm/themes/$SDDM_THEME_NAME/"
else
    error "Theme template not found: $SDDM_THEME_TPL"
fi

echo
log "You can preview your updated SDDM Login screen. (Close it with SUPER+Q)"
echo

# Preview option
if [[ "$USE_GUM" == true ]]; then
    if gum confirm "Do you want to preview the result?"; then
        if command -v sddm-greeter-qt6 >/dev/null 2>&1; then
            sddm-greeter-qt6 --test-mode --theme "/usr/share/sddm/themes/$SDDM_THEME_NAME" || true
        else
            log "sddm-greeter-qt6 not found, skipping preview"
        fi
    fi
    echo
    gum spin --spinner dot --title "Please logout to see the result." -- sleep 3
else
    log "Please logout to see the result."
fi
