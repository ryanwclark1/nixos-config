#!/usr/bin/env bash

# -----------------------------------------------------
# System Tools Launcher Utilities
# Shared utilities for launching system management tools
# -----------------------------------------------------
#
# This script provides shared utilities for detecting and launching
# system management tools, monitors, and diagnostic utilities.
# -----------------------------------------------------

set -euo pipefail

# Source app launcher if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/os-app-launcher.sh" ]]; then
    # shellcheck source=os-app-launcher.sh
    source "$SCRIPT_DIR/os-app-launcher.sh"
fi

# Launch system monitor
launch_system_monitor() {
    local notify_func="${1:-}"

    if command -v launch_system_monitor >/dev/null 2>&1; then
        # Use shared launcher if available
        if launch_system_monitor; then
            [[ -n "$notify_func" ]] && $notify_func -u low "󰍹 System Monitor" "Launched system monitor" -t 3000
            return 0
        fi
    else
        # Fallback: try common monitors
        local monitor_apps=("btop" "htop" "gotop" "bashtop" "bpytop" "top")

        for monitor in "${monitor_apps[@]}"; do
            if command -v "$monitor" >/dev/null 2>&1; then
                if command -v launch_terminal_with_command >/dev/null 2>&1; then
                    if launch_terminal_with_command "$monitor"; then
                        [[ -n "$notify_func" ]] && $notify_func -u low "󰍹 System Monitor" "Launched $monitor" -t 3000
                        return 0
                    fi
                else
                    # Fallback terminal launch
                    local terminals=("ghostty" "kitty" "alacritty" "gnome-terminal" "konsole" "xfce4-terminal")
                    for terminal in "${terminals[@]}"; do
                        if command -v "$terminal" >/dev/null 2>&1; then
                            "$terminal" -e "$monitor" &
                            [[ -n "$notify_func" ]] && $notify_func -u low "󰍹 System Monitor" "Launched $monitor in $terminal" -t 3000
                            return 0
                        fi
                    done
                fi
            fi
        done
    fi

    [[ -n "$notify_func" ]] && $notify_func -u normal "󰍹 System Monitor" "No suitable system monitor or terminal found. Install btop, htop, or similar." -t 5000
    return 1
}

# Launch system management tools (GUI)
launch_system_tools() {
    local notify_func="${1:-}"
    local tools_launched=false

    local system_tools=(
        "gnome-system-monitor:GNOME System Monitor"
        "ksysguard:KDE System Guard"
        "plasma-systemmonitor:KDE Plasma System Monitor"
        "xfce4-taskmanager:XFCE Task Manager"
        "mate-system-monitor:MATE System Monitor"
        "lxtask:LXDE Task Manager"
        "qps:Qt Process Manager"
        "gnome-control-center:GNOME Settings"
        "systemsettings6:KDE Settings 6"
        "systemsettings5:KDE Settings 5"
        "systemsettings:KDE Settings"
    )

    for tool_entry in "${system_tools[@]}"; do
        local tool_cmd="${tool_entry%%:*}"
        local tool_name="${tool_entry##*:}"

        if command -v "$tool_cmd" >/dev/null 2>&1; then
            if "$tool_cmd" >/dev/null 2>&1 &; then
                [[ -n "$notify_func" ]] && $notify_func -u low "🔧 System Tools" "Launched $tool_name" -t 3000
                tools_launched=true
                break
            else
                [[ -n "$notify_func" ]] && $notify_func -u normal "⚠️ Error" "Failed to launch $tool_name" -t 4000
            fi
        fi
    done

    if [[ "$tools_launched" == false ]]; then
        [[ -n "$notify_func" ]] && $notify_func -u normal "🔧 System Tools" "No suitable system management tools found. Install gnome-system-monitor, ksysguard, or similar." -t 5000
        return 1
    fi

    return 0
}

# Launch diagnostic tool in terminal
launch_diagnostic_tool() {
    local notify_func="${1:-}"
    local polkit_cmd="${2:-}"

    # Find available diagnostic tool
    local diagnostic_candidates=(
        "powertop"         # Intel PowerTOP - best for power analysis
        "btop"            # Modern system monitor with better UI
        "htop"            # Enhanced top with better interface
        "gotop"           # Terminal based graphical activity monitor
        "ytop"            # System monitor written in Rust
        "bashtop"         # Resource monitor in bash
        "bpytop"          # Python version of bashtop
        "tlp-stat"        # TLP power management statistics
        "top"             # Traditional system monitor (fallback)
    )

    local diagnostic_tool=""
    for tool in "${diagnostic_candidates[@]}"; do
        # Handle tools with arguments
        local tool_cmd="${tool%% *}"
        if command -v "$tool_cmd" >/dev/null 2>&1; then
            diagnostic_tool="$tool"
            break
        fi
    done

    if [[ -z "$diagnostic_tool" ]]; then
        [[ -n "$notify_func" ]] && $notify_func -u normal "󱎘 Diagnose" "No suitable diagnostic tool found. Consider installing: powertop, auto-cpufreq, btop, htop, tlp-stat (power/system monitors)" -t 5000
        return 1
    fi

    # Launch in terminal using shared launcher if available
    if command -v launch_terminal_with_command >/dev/null 2>&1; then
        if [[ "$diagnostic_tool" == "powertop" && -n "$polkit_cmd" ]]; then
            # PowerTOP needs root privileges
            ${polkit_cmd} sh -c "launch_terminal_with_command powertop"
        else
            launch_terminal_with_command $diagnostic_tool
        fi
        return 0
    else
        # Fallback: manual terminal launch
        local terminal=""
        local terminals=("ghostty" "kitty" "alacritty" "foot" "wezterm" "gnome-terminal" "konsole" "xfce4-terminal")

        for term in "${terminals[@]}"; do
            if command -v "$term" >/dev/null 2>&1; then
                terminal="$term"
                break
            fi
        done

        if [[ -z "$terminal" ]]; then
            [[ -n "$notify_func" ]] && $notify_func -u normal "󱎘 Diagnose" "No suitable terminal found. Consider installing: ghostty, kitty, alacritty (terminals)" -t 5000
            return 1
        fi

        # Handle different terminal syntaxes
        local term_args=()
        case "$terminal" in
            "ghostty"|"kitty"|"alacritty"|"foot")
                term_args=("-e" "$diagnostic_tool")
                ;;
            "wezterm")
                term_args=("start" "--" "$diagnostic_tool")
                ;;
            "gnome-terminal"|"tilix")
                term_args=("--" "$diagnostic_tool")
                ;;
            *)
                term_args=("-e" "$diagnostic_tool")
                ;;
        esac

        if [[ "$diagnostic_tool" == "powertop" && -n "$polkit_cmd" ]]; then
            ${polkit_cmd} "$terminal" "${term_args[@]}"
        else
            "$terminal" "${term_args[@]}" &
        fi
        return 0
    fi
}
