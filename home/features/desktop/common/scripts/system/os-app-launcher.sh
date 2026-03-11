#!/usr/bin/env bash

# -----------------------------------------------------
# Application Launcher Utilities
# Shared utilities for launching applications with fallbacks
# -----------------------------------------------------
#
# This script provides shared utilities for launching applications,
# with automatic fallback detection and proper error handling.
# -----------------------------------------------------

set -euo pipefail

# Launch terminal application
launch_terminal() {
    local terminal_candidates=(
        "ghostty"
        "kitty"
        "alacritty"
        "foot"
        "wezterm"
        "gnome-terminal"
        "konsole"
        "xfce4-terminal"
        "tilix"
        "termite"
        "sakura"
        "st"
        "urxvt"
        "xterm"
    )

    for terminal in "${terminal_candidates[@]}"; do
        if command -v "$terminal" >/dev/null 2>&1; then
            "$terminal" "$@" &
            return 0
        fi
    done

    echo "Error: No suitable terminal found" >&2
    return 1
}

# Launch terminal with command
launch_terminal_with_command() {
    local command="$1"
    shift
    local terminal_candidates=(
        "ghostty"
        "kitty"
        "alacritty"
        "foot"
        "wezterm"
        "gnome-terminal"
        "konsole"
        "xfce4-terminal"
        "tilix"
        "termite"
        "sakura"
        "st"
        "urxvt"
        "xterm"
    )

    for terminal in "${terminal_candidates[@]}"; do
        if command -v "$terminal" >/dev/null 2>&1; then
            case "$terminal" in
                "ghostty"|"kitty"|"alacritty"|"foot")
                    "$terminal" -e "$command" "$@" &
                    ;;
                "wezterm")
                    "$terminal" start -- "$command" "$@" &
                    ;;
                "gnome-terminal"|"tilix")
                    "$terminal" -- "$command" "$@" &
                    ;;
                "konsole"|"xfce4-terminal"|"termite"|"sakura"|"st"|"urxvt"|"xterm")
                    "$terminal" -e "$command" "$@" &
                    ;;
                *)
                    "$terminal" -e "$command" "$@" &
                    ;;
            esac
            return 0
        fi
    done

    echo "Error: No suitable terminal found" >&2
    return 1
}

# Launch file manager
launch_file_manager() {
    local file_manager_candidates=(
        "nautilus"
        "thunar"
        "dolphin"
        "pcmanfm"
        "nemo"
        "caja"
        "ranger"
    )

    for fm in "${file_manager_candidates[@]}"; do
        if command -v "$fm" >/dev/null 2>&1; then
            "$fm" "$@" &
            return 0
        fi
    done

    echo "Error: No suitable file manager found" >&2
    return 1
}

# Launch code editor
launch_code_editor() {
    local editor_candidates=(
        "code"
        "codium"
        "nvim"
        "vim"
        "gedit"
        "gnome-text-editor"
        "mousepad"
        "kate"
    )

    for editor in "${editor_candidates[@]}"; do
        if command -v "$editor" >/dev/null 2>&1; then
            "$editor" "$@" &
            return 0
        fi
    done

    echo "Error: No suitable code editor found" >&2
    return 1
}

# Launch browser
launch_browser() {
    local browser_candidates=(
        "google-chrome"
        "chromium"
        "firefox"
        "brave"
        "vivaldi"
        "opera"
    )

    for browser in "${browser_candidates[@]}"; do
        if command -v "$browser" >/dev/null 2>&1; then
            "$browser" "$@" &
            return 0
        fi
    done

    echo "Error: No suitable browser found" >&2
    return 1
}

# Launch system monitor
launch_system_monitor() {
    local monitor_candidates=(
        "btop"
        "htop"
        "gotop"
        "bashtop"
        "bpytop"
        "top"
    )

    for monitor in "${monitor_candidates[@]}"; do
        if command -v "$monitor" >/dev/null 2>&1; then
            launch_terminal_with_command "$monitor"
            return 0
        fi
    done

    echo "Error: No suitable system monitor found" >&2
    return 1
}

# Launch calculator
launch_calculator() {
    local calc_candidates=(
        "gnome-calculator"
        "qalculate-gtk"
        "galculator"
        "kcalc"
    )

    for calc in "${calc_candidates[@]}"; do
        if command -v "$calc" >/dev/null 2>&1; then
            "$calc" &
            return 0
        fi
    done

    echo "Error: No suitable calculator found" >&2
    return 1
}

# Launch text editor
launch_text_editor() {
    local editor_candidates=(
        "gnome-text-editor"
        "gedit"
        "mousepad"
        "kate"
        "leafpad"
    )

    for editor in "${editor_candidates[@]}"; do
        if command -v "$editor" >/dev/null 2>&1; then
            "$editor" "$@" &
            return 0
        fi
    done

    echo "Error: No suitable text editor found" >&2
    return 1
}
