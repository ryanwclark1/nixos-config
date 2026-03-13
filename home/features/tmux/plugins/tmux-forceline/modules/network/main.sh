#!/usr/bin/env bash
set -euo pipefail
source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/source_helpers.sh"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$CURRENT_DIR/functions.sh"

# Read tmux options
interface="$(get_tmux_option "@forceline_network_interface" "")"
unit="$(get_tmux_option "@forceline_network_unit" "auto")"
show_interface="$(get_tmux_option "@forceline_network_show_interface" "no")"

cmd="${1:-}"; shift || true

# Validate unit
[[ "$unit" =~ ^(auto|B|KB|MB|GB)$ ]] || unit="auto"

# Auto-detect interface if not specified or set to "auto"
if [ -z "$interface" ] || [ "$interface" = "auto" ]; then
    interface=$(get_primary_interface)
fi

if [ -z "$interface" ]; then
    echo "N/A"
    exit 1
fi

# Get interface statistics
stats=""
if [[ "$OSTYPE" == "darwin"* ]]; then
    stats=$(get_macos_network_stats "$interface") || true
else
    stats=$(get_linux_network_stats "$interface") || true
fi

if [ -z "$stats" ]; then
    echo "N/A"
    exit 1
fi

case "$cmd" in
    bandwidth)
        calculate_bandwidth "$stats" "$interface" "$unit"
        ;;
    interface)
        echo "$interface"
        ;;
    total)
        IFS=: read -r rx_bytes tx_bytes <<< "$stats"
        rx_formatted=$(format_bytes "$rx_bytes" "$unit")
        tx_formatted=$(format_bytes "$tx_bytes" "$unit")
        echo "↓${rx_formatted} ↑${tx_formatted}"
        ;;
    *)
        calculate_bandwidth "$stats" "$interface" "$unit"
        ;;
esac
