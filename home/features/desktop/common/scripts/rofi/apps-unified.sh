#!/usr/bin/env bash

# Unified Application Launcher
# Replaces both apps.sh and appasroot.sh with a cleaner, more flexible approach

# Configuration
ROFI_THEME_TYPE="${ROFI_APP_THEME_TYPE:-type-3}"
ROFI_THEME_STYLE="${ROFI_APP_THEME_STYLE:-style-3.rasi}"
THEME_PATH="$HOME/.config/rofi/applets/$ROFI_THEME_TYPE/$ROFI_THEME_STYLE"

# Check if we should run as root (first argument)
RUN_AS_ROOT="${1:-false}"

if [[ "$RUN_AS_ROOT" == "--root" ]] || [[ "$RUN_AS_ROOT" == "root" ]]; then
    MODE="root"
    PROMPT="Root Applications"
    MESSAGE="Run Applications with Administrator Privileges"
else
    MODE="user"
    PROMPT="Applications"
    MESSAGE="Launch Favorite Applications"
fi

# Theme detection and layout
if [[ -f "$THEME_PATH" ]]; then
    LAYOUT=$(grep 'USE_ICON' "$THEME_PATH" 2>/dev/null | cut -d'=' -f2 | tr -d ' "'"'" || echo "YES")

    # Set grid layout based on theme type
    if [[ "$ROFI_THEME_TYPE" == *"type-1"* ]] || [[ "$ROFI_THEME_TYPE" == *"type-3"* ]] || [[ "$ROFI_THEME_TYPE" == *"type-5"* ]]; then
        COLUMNS=1
        ROWS=6
        WIN_WIDTH="400px"
    else
        COLUMNS=6
        ROWS=1
        WIN_WIDTH="720px"
    fi
else
    LAYOUT="YES"
    COLUMNS=1
    ROWS=6
    WIN_WIDTH="400px"
fi

# Application definitions
if [[ "$MODE" == "root" ]]; then
    # Root applications - only apps that actually need root access
    if [[ "$LAYOUT" == "NO" ]]; then
        # Text mode with descriptive labels
        APP_TERMINAL="󰊠  Root Terminal"
        APP_FILEMANAGER="󰉋  File Manager (Root)"
        APP_EDITOR="  System Editor"
        APP_SYSTEMCTL="󰓦  System Services"
        APP_LOGS="󰌪  System Logs"
        APP_DISKS="󰆼  Disk Management"
    else
        # Icon-only mode
        APP_TERMINAL="󰊠"
        APP_FILEMANAGER="󰉋"
        APP_EDITOR=""
        APP_SYSTEMCTL="󰓦"
        APP_LOGS="󰌪"
        APP_DISKS="󰆼"
    fi

    # Commands for root applications
    CMD_TERMINAL="pkexec env PATH=\$PATH WAYLAND_DISPLAY=\$WAYLAND_DISPLAY XDG_RUNTIME_DIR=\$XDG_RUNTIME_DIR kitty"
    CMD_FILEMANAGER="pkexec env PATH=\$PATH WAYLAND_DISPLAY=\$WAYLAND_DISPLAY XDG_RUNTIME_DIR=\$XDG_RUNTIME_DIR nautilus"
    CMD_EDITOR="pkexec env PATH=\$PATH WAYLAND_DISPLAY=\$WAYLAND_DISPLAY XDG_RUNTIME_DIR=\$XDG_RUNTIME_DIR kitty -e nvim"
    CMD_SYSTEMCTL="pkexec env PATH=\$PATH WAYLAND_DISPLAY=\$WAYLAND_DISPLAY XDG_RUNTIME_DIR=\$XDG_RUNTIME_DIR kitty -e systemctl"
    CMD_LOGS="pkexec env PATH=\$PATH WAYLAND_DISPLAY=\$WAYLAND_DISPLAY XDG_RUNTIME_DIR=\$XDG_RUNTIME_DIR kitty -e journalctl -f"
    CMD_DISKS="pkexec gparted"

    OPTIONS="$APP_TERMINAL\n$APP_FILEMANAGER\n$APP_EDITOR\n$APP_SYSTEMCTL\n$APP_LOGS\n$APP_DISKS"
else
    # User applications - common daily apps
    if [[ "$LAYOUT" == "NO" ]]; then
        # Text mode with app details
        APP_TERMINAL="󰊠  Terminal"
        APP_FILEMANAGER="󰉋  File Manager"
        APP_EDITOR="󰨞  Code Editor"
        APP_BROWSER="󰖟  Web Browser"
        APP_MUSIC="󰝚  Music Player"
        APP_SETTINGS="󰒓  System Settings"
    else
        # Icon-only mode
        APP_TERMINAL="󰊠"
        APP_FILEMANAGER="󰉋"
        APP_EDITOR="󰨞"
        APP_BROWSER="󰖟"
        APP_MUSIC="󰝚"
        APP_SETTINGS="󰒓"
    fi

    # Commands for user applications
    CMD_TERMINAL="kitty"
    CMD_FILEMANAGER="nautilus"
    CMD_EDITOR="code"
    CMD_BROWSER="google-chrome"
    CMD_MUSIC="kitty -e ncmpcpp"
    CMD_SETTINGS="$HOME/.config/hypr/scripts/rofi/settings-menu.sh"

    OPTIONS="$APP_TERMINAL\n$APP_FILEMANAGER\n$APP_EDITOR\n$APP_BROWSER\n$APP_MUSIC\n$APP_SETTINGS"
fi

# Rofi command
rofi_cmd() {
    rofi -dmenu \
        -p "$PROMPT" \
        -mesg "$MESSAGE" \
        -markup-rows \
        -theme "$THEME_PATH" \
        -theme-str "window { width: $WIN_WIDTH; }" \
        -theme-str "listview { columns: $COLUMNS; lines: $ROWS; }" \
        -theme-str 'textbox-prompt-colon { str: " "; }'
}

# Show menu and get selection
CHOICE=$(echo -e "$OPTIONS" | rofi_cmd)

# Exit if nothing selected
[[ -z "$CHOICE" ]] && exit 0

# Execute based on choice
case "$CHOICE" in
    "$APP_TERMINAL")
        eval "$CMD_TERMINAL" &
        ;;
    "$APP_FILEMANAGER")
        eval "$CMD_FILEMANAGER" &
        ;;
    "$APP_EDITOR")
        eval "$CMD_EDITOR" &
        ;;
    "$APP_BROWSER")
        eval "$CMD_BROWSER" &
        ;;
    "$APP_SYSTEMCTL")
        eval "$CMD_SYSTEMCTL" &
        ;;
    "$APP_MUSIC")
        eval "$CMD_MUSIC" &
        ;;
    "$APP_LOGS")
        eval "$CMD_LOGS" &
        ;;
    "$APP_SETTINGS")
        eval "$CMD_SETTINGS" &
        ;;
    "$APP_DISKS")
        eval "$CMD_DISKS" &
        ;;
esac
