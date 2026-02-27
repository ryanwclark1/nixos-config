#!/usr/bin/env bash

# Linux Bluetooth Manager with FZF
# Compatible with NixOS and other Linux distributions

set -euo pipefail

# Catppuccin Frappé colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly RESET='\033[0m'

# Helper functions
err() {
    printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2
}

info() {
    printf "${BLUE}[INFO]${RESET} %s\n" "$*"
}

success() {
    printf "${GREEN}[SUCCESS]${RESET} %s\n" "$*"
}

warn() {
    printf "${YELLOW}[WARNING]${RESET} %s\n" "$*"
}

has() {
    local verbose=false
    if [[ $1 == '-v' ]]; then
        verbose=true
        shift
    fi
    for cmd in "$@"; do
        if ! command -v "${cmd%% *}" &>/dev/null; then
            [[ "$verbose" == true ]] && err "$cmd not found"
            return 1
        fi
    done
}

die() {
    [[ $# -gt 0 ]] && err "$*"
    exit 1
}

# Check dependencies
check_deps() {
    if ! has fzf bluetoothctl; then
        err "This script requires fzf and bluetoothctl to be installed"
        err "On NixOS, ensure bluetooth is enabled in your configuration"
        exit 1
    fi

    # Check if bluetooth service is running
    if ! systemctl is-active --quiet bluetooth; then
        err "Bluetooth service is not running"
        err "Try: sudo systemctl start bluetooth"
        exit 1
    fi
}

# Get paired devices
get_paired_devices() {
    local address name status device_class info_output
    while IFS= read -r line; do
        # Parse bluetoothctl output: Device XX:XX:XX:XX:XX:XX DeviceName
        address=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | cut -d' ' -f3-)

        # Skip if address is empty
        [[ -z "$address" ]] && continue

        # Get connection status
        info_output=$(bluetoothctl info "$address" 2>/dev/null)
        if echo "$info_output" | grep -q "Connected: yes"; then
            status="${GREEN}✔ Connected${RESET}"
        else
            status="${RED}✗ Disconnected${RESET}"
        fi

        # Get device type/class
        device_class=$(echo "$info_output" | grep "Class:" | cut -d' ' -f2- || echo "Unknown")

        printf "%s\t%s\t%s\t%s\n" "$address" "$name" "$status" "$device_class"
    done < <(bluetoothctl devices Paired 2>/dev/null || true)
}

# Toggle device connection
toggle_connection() {
    local address="$1"
    local name="$2"

    info "Processing $name ($address)..."

    if bluetoothctl info "$address" | grep -q "Connected: yes"; then
        info "Disconnecting $name..."
        if bluetoothctl disconnect "$address" &>/dev/null; then
            success "Disconnected $name"
        else
            err "Failed to disconnect $name"
        fi
    else
        info "Connecting to $name..."
        if bluetoothctl connect "$address" &>/dev/null; then
            success "Connected to $name"
        else
            err "Failed to connect to $name"
            warn "Device might need to be in pairing mode"
        fi
    fi
}

# Scan for new devices
scan_devices() {
    info "Scanning for devices (30 seconds)..."
    bluetoothctl --timeout 30 scan on >/dev/null 2>&1 &
    local scan_pid=$!

    # Show discovered devices after a brief delay
    sleep 2
    local address name
    while IFS= read -r line; do
        # Skip paired devices
        [[ "$line" =~ "Paired" ]] && continue

        # Parse device line
        address=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | cut -d' ' -f3-)

        [[ -n "$address" ]] && printf "%s\t%s\t${YELLOW}Available${RESET}\t%s\n" "$address" "$name" "Discovered"
    done < <(bluetoothctl devices 2>/dev/null || true)

    wait "$scan_pid" 2>/dev/null || true
}

# Pair with new device
pair_device() {
    local address="$1"
    local name="$2"

    info "Pairing with $name ($address)..."

    if bluetoothctl pair "$address" && bluetoothctl trust "$address"; then
        success "Successfully paired with $name"
        if bluetoothctl connect "$address"; then
            success "Connected to $name"
        fi
    else
        err "Failed to pair with $name"
        warn "Make sure the device is in pairing mode"
    fi
}

# Main interactive function
main() {
    check_deps

    while true; do
        # Create menu header
        local header="${BLUE}Bluetooth Device Manager${RESET}
${GREEN}<Enter>${RESET} toggle connection | ${YELLOW}<Ctrl-S>${RESET} scan | ${RED}<Ctrl-Q>${RESET} quit | ${CYAN}?${RESET} help"

        # Get current devices and show menu
        local selection
        selection=$(
            {
                echo -e "Action\tDevice\tStatus\tType"
                get_paired_devices
            } | fzf --ansi \
                --header="$header" \
                --delimiter='\t' \
                --with-nth=2,3,4 \
                --expect=ctrl-s,ctrl-q,ctrl-p \
                --bind='?:preview:echo -e "KEYBINDINGS:\n\n<Enter> - Toggle device connection\n<Ctrl-S> - Scan for new devices\n<Ctrl-P> - Pair with device\n<Ctrl-Q> - Quit\n? - Show this help"' \
                --preview='bluetoothctl info {1} 2>/dev/null || echo "No device info available"' \
                --preview-window=right:60%:wrap
        ) || break

        local key="${selection%%$'\n'*}"
        local device_line="${selection#*$'\n'}"

        # Skip header line
        [[ "$device_line" =~ ^Action ]] && continue

        case "$key" in
            ctrl-q)
                info "Goodbye!"
                break
                ;;
            ctrl-s)
                info "Starting device scan..."
                scan_devices
                continue
                ;;
            ctrl-p)
                if [[ -n "$device_line" ]]; then
                    IFS=$'\t' read -r address name _ _ <<< "$device_line"
                    [[ -n "$address" ]] && pair_device "$address" "$name"
                fi
                ;;
            "")
                if [[ -n "$device_line" ]]; then
                    IFS=$'\t' read -r address name _ _ <<< "$device_line"
                    [[ -n "$address" ]] && toggle_connection "$address" "$name"
                fi
                ;;
        esac

        # Pause to show result
        sleep 1
    done
}

# Show help
show_help() {
    cat << 'EOF'
Linux Bluetooth Manager with FZF

USAGE:
    bluetoothz.sh [OPTIONS]

OPTIONS:
    -h, --help    Show this help message

KEYBINDINGS:
    <Enter>       Toggle device connection
    <Ctrl-S>      Scan for new devices
    <Ctrl-P>      Pair with selected device
    <Ctrl-Q>      Quit application
    ?             Show help in preview

REQUIREMENTS:
    - bluetoothctl (bluez package)
    - fzf
    - Active bluetooth service

EXAMPLES:
    bluetoothz.sh                 # Interactive device manager
    sudo systemctl start bluetooth   # Start bluetooth service
EOF
}

# Parse arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
