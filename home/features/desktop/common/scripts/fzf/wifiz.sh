#!/usr/bin/env bash

# Enhanced WiFi Network Selector with FZF
# NetworkManager-based WiFi connection with improved UI

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

warn() {
    printf "${YELLOW}[WARNING]${RESET} %s\n" "$*"
}

success() {
    printf "${GREEN}[SUCCESS]${RESET} %s\n" "$*"
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

# Check if NetworkManager is available and running
check_networkmanager() {
    if ! has nmcli; then
        err "NetworkManager (nmcli) is not installed"
        err "Install NetworkManager or use your distribution's network manager"
        return 1
    fi

    if ! systemctl is-active --quiet NetworkManager 2>/dev/null; then
        err "NetworkManager service is not running"
        err "Try: sudo systemctl start NetworkManager"
        return 1
    fi

    # Check if WiFi is enabled
    if [[ "$(nmcli radio wifi)" == "disabled" ]]; then
        warn "WiFi is disabled"
        info "Enabling WiFi..."
        if ! nmcli radio wifi on; then
            err "Failed to enable WiFi"
            return 1
        fi
        sleep 2  # Give time for WiFi to activate
    fi
}

# Get WiFi device info
get_wifi_device() {
    local device
    device=$(nmcli -t -f DEVICE,TYPE device status | grep "wifi" | head -1 | cut -d: -f1)

    if [[ -z "$device" ]]; then
        err "No WiFi device found"
        return 1
    fi

    echo "$device"
}

# Show help
show_help() {
    cat << 'EOF'
Enhanced WiFi Network Selector

USAGE:
    wifiz.sh [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -r, --rescan        Force rescan before showing networks
    -s, --saved         Show saved connections only
    --show-hidden       Include hidden networks

KEYBINDINGS:
    <Enter>             Connect to selected network
    <Ctrl-R>            Rescan for networks
    <Ctrl-S>            Show saved connections
    <Ctrl-F>            Forget selected saved network
    <Ctrl-D>            Disconnect from current network
    <Esc>               Quit
    ?                   Show help in preview

FEATURES:
    - Real-time signal strength display
    - Security type indicators
    - Connection status
    - Network frequency information
    - Saved network management

EXAMPLES:
    wifiz.sh                 # Interactive WiFi selector
    wifiz.sh -r              # Force rescan first
    wifiz.sh -s              # Show saved networks only
EOF
}

# Main function
main() {
    local force_rescan=false
    local saved_only=false
    local show_hidden=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -r|--rescan)
                force_rescan=true
                shift
                ;;
            -s|--saved)
                saved_only=true
                shift
                ;;
            --show-hidden)
                show_hidden=true
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                err "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                err "Unexpected argument: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Check dependencies
    if ! has -v fzf; then
        err "This script requires fzf to be installed"
        exit 1
    fi

    if ! check_networkmanager; then
        exit 1
    fi

    # Get WiFi device
    local wifi_device
    if ! wifi_device=$(get_wifi_device); then
        exit 1
    fi

    info "Using WiFi device: $wifi_device"

    # Force rescan if requested
    if [[ "$force_rescan" == true ]]; then
        info "Scanning for networks..."
        if nmcli device wifi rescan 2>/dev/null; then
            sleep 3
            success "Scan complete"
        else
            err "Failed to rescan networks"
            warn "Check WiFi device status: nmcli device status"
        fi
    fi

    # Create header
    local header="WiFi Network Selector | <Enter> connect | <Ctrl-R> rescan | ? help"

    # Build nmcli command - use tab-separated output to handle SSIDs with spaces
    local nmcli_cmd preview_cmd reload_cmd
    local fzf_opts=()

    if [[ "$saved_only" == true ]]; then
        info "Showing saved connections only..."
        nmcli_cmd=(nmcli -t -f 'name,type,autoconnect,state' connection show)
        preview_cmd='nmcli connection show "{1}" 2>/dev/null || echo -e "Name: {1}\nType: {2}\nAuto-connect: {3}\nState: {4}"'
        reload_cmd='nmcli -t -f "name,type,autoconnect,state" connection show'
        fzf_opts=(
            --with-nth=1..
        )
    else
        nmcli_cmd=(nmcli -t -f 'bssid,signal,bars,freq,security,ssid' device wifi)
        preview_cmd='echo -e "BSSID: {1}\nSignal: {2}%\nBars: {3}\nFrequency: {4} MHz\nSecurity: {5}\nSSID: {6}\n\nDevice: $(nmcli -t -f device device status | grep wifi | head -1)\nWiFi Status: $(nmcli radio wifi)"'
        reload_cmd='nmcli device wifi rescan; sleep 2; nmcli -t -f "bssid,signal,bars,freq,security,ssid" device wifi'
        fzf_opts=(
            --with-nth=6,2,3,4,5
        )
    fi

    # Main FZF interface
    local selected
    selected=$(
        "${nmcli_cmd[@]}" 2>/dev/null |
        fzf --ansi \
            -i \
            --header="$header" \
            --header-lines=1 \
            --delimiter='\t' \
            "${fzf_opts[@]}" \
            --expect='ctrl-r,ctrl-s,ctrl-f,ctrl-d' \
            --preview="$preview_cmd" \
            --preview-window='right,50%,border-left,wrap' \
            --bind="ctrl-r:reload($reload_cmd)" \
            --bind='?:preview:echo -e "KEYBINDINGS:\n\n<Enter> - Connect to network\n<Ctrl-R> - Rescan networks\n<Ctrl-S> - Show saved connections\n<Ctrl-F> - Forget saved network\n<Ctrl-D> - Disconnect current\n<Esc> - Quit\n\nCOLOR CODES:\n- Green: Connected\n- Yellow: Available\n- Red: Requires password\n- Blue: Open network"' \
            --height=80% \
            --reverse \
            --cycle \
            --inline-info
    ) || exit $?

    # Parse selection
    local key="${selected%%$'\n'*}"
    local network_line="${selected#*$'\n'}"

    [[ -z "$network_line" ]] && exit 0

    # Extract network information - fields are tab-separated
    local bssid ssid
    if [[ "$saved_only" == true ]]; then
        # Saved connections: name,type,autoconnect,state
        IFS=$'\t' read -r ssid _ _ _ <<< "$network_line"
    else
        # WiFi networks: bssid,signal,bars,freq,security,ssid
        IFS=$'\t' read -r bssid _ _ _ _ ssid <<< "$network_line"
    fi

    # Validate we got the required information
    if [[ -z "$ssid" ]]; then
        err "Failed to parse network information"
        exit 1
    fi

    case "$key" in
        ctrl-r)
            info "Rescanning networks..."
            nmcli device wifi rescan
            success "Rescan complete"
            ;;
        ctrl-s)
            info "Showing saved connections..."
            # Re-run with saved connections view
            exec "$0" -s
            ;;
        ctrl-f)
            if [[ "$saved_only" == true ]]; then
                warn "About to forget connection: $ssid"
                printf "${YELLOW}Continue? (y/N): ${RESET}"
                read -r response
                if [[ "$response" =~ ^[Yy]$ ]]; then
                    if nmcli connection delete "$ssid"; then
                        success "Forgot connection: $ssid"
                    else
                        err "Failed to forget connection: $ssid"
                    fi
                else
                    info "Operation cancelled"
                fi
            else
                warn "Use -s flag to manage saved connections"
            fi
            ;;
        ctrl-d)
            info "Disconnecting from current network..."
            if nmcli device disconnect "$wifi_device"; then
                success "Disconnected from network"
            else
                err "Failed to disconnect"
            fi
            ;;
        "")
            # Connect to network
            if [[ "$saved_only" == true ]]; then
                info "Activating connection: $ssid"
                if nmcli connection up "$ssid" 2>/dev/null; then
                    sleep 2
                    # Verify connection
                    if nmcli -t -f active,ssid device wifi list | grep -q "^yes:$ssid"; then
                        success "Successfully activated connection: $ssid"
                    else
                        warn "Connection activated but may not be active yet"
                    fi
                else
                    err "Failed to activate connection: $ssid"
                    warn "Check if the connection profile exists: nmcli connection show"
                fi
            else
                info "Connecting to: $ssid"
                local connect_success=false
                local max_retries=2
                local retry_count=0

                # Try BSSID first if available, then fall back to SSID
                while (( retry_count < max_retries && connect_success == false )); do
                    if [[ -n "$bssid" ]]; then
                        if nmcli -a device wifi connect "$bssid" 2>/dev/null; then
                            connect_success=true
                        fi
                    fi

                    if [[ "$connect_success" == false ]]; then
                        if nmcli -a device wifi connect "$ssid" 2>/dev/null; then
                            connect_success=true
                        fi
                    fi

                    if [[ "$connect_success" == true ]]; then
                        sleep 3
                        # Verify connection
                        local connection_status
                        connection_status=$(nmcli -t -f active,ssid device wifi list 2>/dev/null | grep "^yes:" | head -1 | cut -d: -f2)
                        if [[ "$connection_status" == "$ssid" ]]; then
                            success "Successfully connected to: $ssid"
                        else
                            warn "Connection initiated but verification pending"
                        fi
                        break
                    fi

                    ((retry_count++))
                    if (( retry_count < max_retries )); then
                        sleep 1
                    fi
                done

                if [[ "$connect_success" == false ]]; then
                    err "Failed to connect to: $ssid after $max_retries attempts"
                    warn "Check password, network availability, or device status"
                    warn "The network may require manual configuration"
                    warn "Try: nmcli device wifi connect \"$ssid\" password <password>"
                fi
            fi
            ;;
    esac
}

# Handle if sourced vs executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
