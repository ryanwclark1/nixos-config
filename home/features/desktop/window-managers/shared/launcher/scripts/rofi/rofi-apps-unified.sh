#!/usr/bin/env bash
set -euo pipefail

# Unified Application Launcher
# Replaces both apps.sh and appasroot.sh with a cleaner, more flexible approach

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find and source shared utilities
ROFI_HELPERS=""
APP_LAUNCHER=""

if [[ -f "$HOME/.local/bin/scripts/system/os-rofi-helpers.sh" ]]; then
    ROFI_HELPERS="$HOME/.local/bin/scripts/system/os-rofi-helpers.sh"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/system/os-rofi-helpers.sh" ]]; then
    ROFI_HELPERS="$SCRIPT_DIR/../../../../common/scripts/system/os-rofi-helpers.sh"
fi

if [[ -f "$HOME/.local/bin/scripts/system/os-app-launcher.sh" ]]; then
    APP_LAUNCHER="$HOME/.local/bin/scripts/system/os-app-launcher.sh"
elif [[ -f "$SCRIPT_DIR/../../../../common/scripts/system/os-app-launcher.sh" ]]; then
    APP_LAUNCHER="$SCRIPT_DIR/../../../../common/scripts/system/os-app-launcher.sh"
fi

if [[ -n "$ROFI_HELPERS" ]]; then
    # shellcheck source=/dev/null
    source "$ROFI_HELPERS"
fi

if [[ -n "$APP_LAUNCHER" ]]; then
    # shellcheck source=/dev/null
    source "$APP_LAUNCHER"
fi

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

# Theme detection and layout using shared helpers if available
if command -v get_rofi_theme_layout >/dev/null 2>&1 && command -v get_rofi_theme_grid >/dev/null 2>&1; then
    LAYOUT=$(get_rofi_theme_layout "$THEME_PATH")
    grid_info=$(get_rofi_theme_grid "$THEME_PATH")
    read -r COLUMNS ROWS WIN_WIDTH <<< "$grid_info"
else
    # Fallback implementation
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

    # Commands for user applications - use script-relative path for settings
    SETTINGS_SCRIPT="$SCRIPT_DIR/rofi-settings-menu.sh"
    # Fallback to shared scripts if script not found in same directory
    if [[ ! -f "$SETTINGS_SCRIPT" ]]; then
        SETTINGS_SCRIPT="$HOME/.config/desktop/window-managers/shared/scripts/rofi/rofi-settings-menu.sh"
    fi

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

# Execute based on choice - use shared launchers where available
case "$CHOICE" in
    "$APP_TERMINAL")
        if [[ "$MODE" == "root" ]]; then
            pkexec env PATH="$PATH" WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}" \
                XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}" kitty &
        else
            if command -v launch_terminal >/dev/null 2>&1; then
                launch_terminal &
            else
                kitty &
            fi
        fi
        ;;
    "$APP_FILEMANAGER")
        if [[ "$MODE" == "root" ]]; then
            pkexec env PATH="$PATH" WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}" \
                XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}" nautilus &
        else
            if command -v launch_file_manager >/dev/null 2>&1; then
                launch_file_manager &
            else
                nautilus &
            fi
        fi
        ;;
    "$APP_EDITOR")
        if [[ "$MODE" == "root" ]]; then
            pkexec env PATH="$PATH" WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}" \
                XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}" kitty -e nvim &
        else
            if command -v launch_code_editor >/dev/null 2>&1; then
                launch_code_editor &
            else
                code &
            fi
        fi
        ;;
    "$APP_BROWSER")
        if command -v launch_browser >/dev/null 2>&1; then
            launch_browser &
        else
            google-chrome &
        fi
        ;;
    "$APP_SYSTEMCTL")
        pkexec env PATH="$PATH" WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}" \
            XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}" kitty -e systemctl &
        ;;
    "$APP_MUSIC")
        if command -v launch_terminal_with_command >/dev/null 2>&1; then
            launch_terminal_with_command ncmpcpp &
        else
            kitty -e ncmpcpp &
        fi
        ;;
    "$APP_LOGS")
        pkexec env PATH="$PATH" WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}" \
            XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-}" kitty -e journalctl -f &
        ;;
    "$APP_SETTINGS")
        if [[ -f "$SETTINGS_SCRIPT" ]] && [[ -x "$SETTINGS_SCRIPT" ]]; then
            "$SETTINGS_SCRIPT" &
        else
            notify-send "Error" "Settings menu script not found: $SETTINGS_SCRIPT" 2>/dev/null || true
            exit 1
        fi
        ;;
    "$APP_DISKS")
        pkexec gparted &
        ;;
esac
