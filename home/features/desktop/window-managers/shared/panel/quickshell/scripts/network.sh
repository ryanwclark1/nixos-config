
output_status_json() {
    local icon="󰖪"
    local status="disconnected"
    local name="Offline"
    local type=""
    local device=""
    local connectivity="unknown"
    local signal=""
    local link_speed=""
    local security=""
    local vpn_count="0"
    local tailscale_status="Offline"
    local secondary_text=""

    if ! command -v nmcli >/dev/null 2>&1; then
        jq -nc \
            --arg icon "$icon" \
            --arg status "$status" \
            --arg name "$name" \
            --arg type "$type" \
            --arg device "$device" \
            --arg connectivity "$connectivity" \
            --arg signal "$signal" \
            --arg linkSpeed "$link_speed" \
            --arg security "$security" \
            --arg vpnCount "$vpn_count" \
            --arg tailscaleStatus "$tailscale_status" \
            --arg secondaryText "$secondary_text" \
            '{icon: $icon, status: $status, name: $name, type: $type, device: $device, connectivity: $connectivity, signal: $signal, linkSpeed: $linkSpeed, security: $security, vpnCount: ($vpnCount | tonumber), tailscaleStatus: $tailscaleStatus, secondaryText: $secondaryText}'
        return
    fi

    local device_info disabled_count total_count dev_line active_wifi_line speed_raw rate
    device_info=$(nmcli -t -f TYPE,STATE,DEVICE device 2>/dev/null || true)
    disabled_count=$(printf '%s\n' "$device_info" | awk -F: '{print $2}' | grep -c '^unavailable$' || true)
    total_count=$(printf '%s\n' "$device_info" | awk -F: '{print $2}' | grep -c '.' || true)

    if [[ "$total_count" -gt 0 && "$disabled_count" -eq "$total_count" ]]; then
        icon="󰖪"
        status="disabled"
        name="Disabled"
        secondary_text="Networking off"
    else
        connectivity=$(nmcli networking connectivity check 2>/dev/null || nmcli networking connectivity 2>/dev/null || printf 'unknown')
        vpn_count=$(nmcli -t -f NAME,TYPE,STATE connection show --active 2>/dev/null | grep -Ec ':(vpn|wireguard|tun):activated$' || true)
        dev_line=$(nmcli -t -f DEVICE,STATE,TYPE,CONNECTION device status 2>/dev/null | awk -F: '$2=="connected" && ($3=="wifi" || $3=="ethernet") {print; exit}')
        if [[ -z "$dev_line" ]]; then
            dev_line=$(nmcli -t -f DEVICE,STATE,TYPE,CONNECTION device status 2>/dev/null | awk -F: '$2=="connected" {print; exit}')
        fi

        if [[ -n "$dev_line" ]]; then
            device=$(printf '%s' "$dev_line" | awk -F: '{print $1}')
            type=$(printf '%s' "$dev_line" | awk -F: '{print $3}')
            name=$(printf '%s' "$dev_line" | awk -F: '{print $4}')
            [[ -z "$name" ]] && name="Connected"

            if [[ "$type" == "wifi" ]]; then
                active_wifi_line=$(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY,CHAN,RATE dev wifi list 2>/dev/null | awk -F: '$1=="*" {print; exit}')
                if [[ -n "$active_wifi_line" ]]; then
                    name=$(printf '%s' "$active_wifi_line" | awk -F: '{print $2}')
                    signal=$(printf '%s' "$active_wifi_line" | awk -F: '{print $3}')
                    security=$(printf '%s' "$active_wifi_line" | awk -F: '{print $4}')
                    rate=$(printf '%s' "$active_wifi_line" | awk -F: '{print $6}')
                    [[ -n "$rate" ]] && link_speed="$rate"
                fi
                [[ -z "$name" ]] && name="Wi-Fi"
                status="wifi"

                if [[ -n "$signal" ]]; then
                    if (( signal >= 80 )); then
                        icon="󰤨"
                    elif (( signal >= 60 )); then
                        icon="󰤥"
                    elif (( signal >= 40 )); then
                        icon="󰤢"
                    elif (( signal > 0 )); then
                        icon="󰤟"
                    else
                        icon="󰤯"
                    fi
                    secondary_text="${signal}%"
                else
                    icon="󰖩"
                    secondary_text="Wi-Fi"
                fi
            elif [[ "$type" == "ethernet" || "$type" == "802-3-ethernet" ]]; then
                speed_raw=$(cat "/sys/class/net/$device/speed" 2>/dev/null || true)
                if [[ -n "$speed_raw" && "$speed_raw" != "-1" ]]; then
                    link_speed="${speed_raw} Mb/s"
                    secondary_text="$link_speed"
                else
                    secondary_text="$device"
                fi
                icon="󰈀"
                status="ethernet"
                name="Ethernet"
            else
                icon=""
                status="linked"
                secondary_text="${device:-Connected}"
            fi
        else
            name="Offline"
            status="disconnected"
            icon="󰤮"
            secondary_text="No connection"
        fi
    fi

    if command -v tailscale >/dev/null 2>&1; then
        if tailscale status --active >/dev/null 2>&1; then
            tailscale_status="Connected"
        else
            tailscale_status="Offline"
        fi
    fi

    jq -nc \
        --arg icon "$icon" \
        --arg status "$status" \
        --arg name "$name" \
        --arg type "$type" \
        --arg device "$device" \
        --arg connectivity "$connectivity" \
        --arg signal "$signal" \
        --arg linkSpeed "$link_speed" \
        --arg security "$security" \
        --arg vpnCount "$vpn_count" \
        --arg tailscaleStatus "$tailscale_status" \
        --arg secondaryText "$secondary_text" \
        '{icon: $icon, status: $status, name: $name, type: $type, device: $device, connectivity: $connectivity, signal: $signal, linkSpeed: $linkSpeed, security: $security, vpnCount: ($vpnCount | tonumber), tailscaleStatus: $tailscaleStatus, secondaryText: $secondaryText}'
}

output_status_json
