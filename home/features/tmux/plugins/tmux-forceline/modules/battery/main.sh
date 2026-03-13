#!/usr/bin/env bash
set -euo pipefail

source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/source_helpers.sh"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$CURRENT_DIR/functions.sh"

cmd="${1:-percentage}"; shift || true

case "$cmd" in
    percentage)
        battery_percentage
        ;;
    status)
        battery_status
        ;;
    color)
        color_type="${1:-bg}"
        percentage=$(get_tmux_option "@_battery_percentage" "")
        status=$(get_tmux_option "@_battery_status" "")
        get_battery_color \
            "$color_type" "$percentage" "$status" \
            "$(get_tmux_option "@forceline_battery_low_threshold" "20")" \
            "$(get_tmux_option "@forceline_battery_critical_threshold" "10")" \
            "$(get_tmux_option "@forceline_battery_charging_bg" "#{@success}")" \
            "$(get_tmux_option "@forceline_battery_charging_fg" "#{@base00}")" \
            "$(get_tmux_option "@forceline_battery_critical_bg" "#{@error}")" \
            "$(get_tmux_option "@forceline_battery_critical_fg" "#{@base00}")" \
            "$(get_tmux_option "@forceline_battery_low_bg" "#{@warning}")" \
            "$(get_tmux_option "@forceline_battery_low_fg" "#{@base00}")" \
            "$(get_tmux_option "@forceline_battery_normal_bg" "#{@surface_0}")" \
            "$(get_tmux_option "@forceline_battery_normal_fg" "#{@fg}")"
        ;;
    icon)
        percentage=$(get_tmux_option "@_battery_percentage" "")
        status=$(get_tmux_option "@_battery_status" "")
        get_battery_icon \
            "$percentage" "$status" \
            "$(get_tmux_option "@batt_icon_status_charging" "󰂄")" \
            "$(get_tmux_option "@batt_icon_status_charged" "󰚥")" \
            "$(get_tmux_option "@batt_icon_status_unknown" "󰂑")" \
            "$(get_tmux_option "@batt_icon_charge_tier8" "󰁹")" \
            "$(get_tmux_option "@batt_icon_charge_tier7" "󰂁")" \
            "$(get_tmux_option "@batt_icon_charge_tier6" "󰁿")" \
            "$(get_tmux_option "@batt_icon_charge_tier5" "󰁾")" \
            "$(get_tmux_option "@batt_icon_charge_tier4" "󰁽")" \
            "$(get_tmux_option "@batt_icon_charge_tier3" "󰁼")" \
            "$(get_tmux_option "@batt_icon_charge_tier2" "󰁻")" \
            "$(get_tmux_option "@batt_icon_charge_tier1" "󰁺")"
        ;;
    *)
        echo "Usage: main.sh {percentage|status|color|icon|init} [args...]" >&2
        exit 1
        ;;
esac
