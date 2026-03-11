#!/usr/bin/env bash

# -----------------------------------------------------
# Power Manager Launcher Utilities
# Shared utilities for launching power management tools
# -----------------------------------------------------
#
# This script provides shared utilities for detecting and launching
# power management tools across different desktop environments,
# session types, and window managers.
# -----------------------------------------------------

set -euo pipefail

# Detect desktop environment
detect_desktop_environment() {
    echo "${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}"
}

# Detect session type
detect_session_type() {
    echo "${XDG_SESSION_TYPE:-unknown}"
}

# Check if running on Wayland
is_wayland() {
    [[ -n "${WAYLAND_DISPLAY:-}" ]] || [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]
}

# Detect if we're in a tiling window manager
is_tiling_wm() {
    local desktop_env
    desktop_env=$(detect_desktop_environment)

    case "${desktop_env,,}" in
        *hyprland*|*sway*|*river*|*niri*|*qtile*|*i3*|*bspwm*|*awesome*|*xmonad*|*dwm*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Launch KDE Plasma power settings
launch_kde_power_settings() {
    local desktop_env
    desktop_env=$(detect_desktop_environment)

    # Check if we're in a KDE environment
    if [[ "$desktop_env" != *"KDE"* ]] && [[ "$desktop_env" != *"plasma"* ]] && [[ "$desktop_env" != *"Plasma"* ]]; then
        return 1
    fi

    # Try Plasma 6 first
    if command -v systemsettings6 >/dev/null 2>&1; then
        systemsettings6 kcm_powerdevilprofilesconfig >/dev/null 2>&1 &
        return $?
    fi

    # Check KDE version
    if command -v systemsettings >/dev/null 2>&1; then
        if command -v kf6-config >/dev/null 2>&1; then
            # Plasma 6
            systemsettings kcm_powerdevilprofilesconfig >/dev/null 2>&1 &
            return $?
        elif command -v kf5-config >/dev/null 2>&1; then
            # Plasma 5
            systemsettings kcm_powerdevilprofilesconfig >/dev/null 2>&1 &
            return $?
        else
            # Fallback
            systemsettings kcm_powerdevilprofilesconfig >/dev/null 2>&1 &
            return $?
        fi
    fi

    # Try Plasma 5 specific
    if command -v systemsettings5 >/dev/null 2>&1; then
        systemsettings5 kcm_powerdevilprofilesconfig >/dev/null 2>&1 &
        return $?
    fi

    return 1
}

# Launch GNOME power settings
launch_gnome_power_settings() {
    local desktop_env
    desktop_env=$(detect_desktop_environment)

    if [[ "$desktop_env" != *"GNOME"* ]]; then
        return 1
    fi

    if command -v gnome-control-center >/dev/null 2>&1; then
        gnome-control-center power >/dev/null 2>&1 &
        return $?
    fi

    return 1
}

# Launch XFCE power manager
launch_xfce_power_settings() {
    local desktop_env
    desktop_env=$(detect_desktop_environment)

    if [[ "$desktop_env" != *"XFCE"* ]]; then
        return 1
    fi

    if command -v xfce4-power-manager-settings >/dev/null 2>&1; then
        xfce4-power-manager-settings &
        return $?
    fi

    return 1
}

# Launch universal power management tools
launch_universal_power_tools() {
    local polkit_cmd="${1:-}"

    # TLP with GUI
    if command -v tlp >/dev/null 2>&1; then
        if command -v tlpui >/dev/null 2>&1; then
            tlpui &
            return 0
        fi
    fi

    # Power profiles daemon
    if command -v powerprofilesctl >/dev/null 2>&1 && systemctl is-active --quiet power-profiles-daemon 2>/dev/null; then
        # Return success but don't launch (would need notification)
        return 0
    fi

    # PowerTOP (needs root)
    if command -v powertop >/dev/null 2>&1; then
        if [[ -n "$polkit_cmd" ]]; then
            ${polkit_cmd} powertop
            return $?
        fi
    fi

    # MATE power manager
    if command -v mate-power-manager >/dev/null 2>&1; then
        mate-power-manager &
        return $?
    fi

    # LXQt power management
    if command -v lxqt-powermanagement >/dev/null 2>&1; then
        lxqt-powermanagement &
        return $?
    fi

    return 1
}

# Launch power manager with automatic detection
launch_power_manager() {
    local notify_func="${1:-}"
    local polkit_cmd="${2:-}"
    local power_manager_launched=false

    local desktop_env
    desktop_env=$(detect_desktop_environment)
    local session_type
    session_type=$(detect_session_type)
    local is_wayland_session
    is_wayland_session=$(is_wayland && echo "true" || echo "false")
    local is_tiling
    is_tiling=$(is_tiling_wm && echo "true" || echo "false")

    # Try DE-specific power managers first
    if launch_kde_power_settings; then
        power_manager_launched=true
        [[ -n "$notify_func" ]] && $notify_func "󰒓 Power Settings" "Opened KDE power settings" -t 3000
    elif launch_gnome_power_settings; then
        power_manager_launched=true
        [[ -n "$notify_func" ]] && $notify_func "󰒓 Power Settings" "Opened GNOME power settings" -t 3000
    elif launch_xfce_power_settings; then
        power_manager_launched=true
        [[ -n "$notify_func" ]] && $notify_func "󰒓 Power Settings" "Opened XFCE power settings" -t 3000
    fi

    # If DE-specific didn't work, try universal tools
    if [[ "$power_manager_launched" == false ]]; then
        if [[ "$is_wayland_session" == "true" && "$is_tiling" == "true" ]]; then
            # Tiling WM on Wayland - prefer universal/CLI tools
            if command -v powerprofilesctl >/dev/null 2>&1 && systemctl is-active --quiet power-profiles-daemon 2>/dev/null; then
                local current_profile
                current_profile=$(powerprofilesctl get 2>/dev/null || echo "unknown")
                [[ -n "$notify_func" ]] && $notify_func "󰒓 Power Profile: $current_profile" "Use 'powerprofilesctl set <profile>' to change. Available: balanced, power-saver, performance" -t 8000
                power_manager_launched=true
            elif launch_universal_power_tools "$polkit_cmd"; then
                power_manager_launched=true
            fi
        else
            # Traditional DE or X11 - try universal tools
            if launch_universal_power_tools "$polkit_cmd"; then
                power_manager_launched=true
            fi
        fi
    fi

    # Provide suggestions if nothing worked
    if [[ "$power_manager_launched" == false ]]; then
        local suggestions=""
        if [[ "$is_tiling" == "true" ]]; then
            suggestions="For tiling WMs: tlp + tlpui, auto-cpufreq, power-profiles-daemon, powertop, or thermald"
        elif [[ "$is_wayland_session" == "true" ]]; then
            suggestions="For Wayland DEs: systemsettings6 (KDE), gnome-control-center power, pwvucontrol, tlp, auto-cpufreq, or power-profiles-daemon"
        else
            suggestions="systemsettings6 (KDE), gnome-control-center power, xfce4-power-manager, auto-cpufreq, tlp, or powertop"
        fi
        [[ -n "$notify_func" ]] && $notify_func "󰒓 Power Manager Not Found" "Consider installing: $suggestions" -t 8000
    fi

    if [[ "$power_manager_launched" == true ]]; then
        return 0
    else
        return 1
    fi
}
