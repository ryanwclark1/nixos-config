#!/usr/bin/env bash
# LAN IP script for tmux-forceline v2.0
# Enhanced local network IP detection with interface selection

# Get tmux option or use default
get_tmux_option() {
    local option="$1"
    local default="$2"
    tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get primary LAN IP
get_primary_lan_ip() {
    local interface_filter="$1"
    local show_interface="$2"
    local ip interface
    
    # Try different methods based on platform
    if command_exists ip; then
        # Linux with iproute2
        if [ -n "$interface_filter" ]; then
            ip=$(ip addr show "$interface_filter" 2>/dev/null | \
                 grep -oE 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | \
                 head -1 | awk '{print $2}')
            interface="$interface_filter"
        else
            # Get default route interface
            interface=$(ip route | grep '^default' | head -1 | sed 's/.*dev \([^ ]*\).*/\1/')
            if [ -n "$interface" ]; then
                ip=$(ip addr show "$interface" 2>/dev/null | \
                     grep -oE 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | \
                     head -1 | awk '{print $2}')
            fi
        fi
    elif command_exists ifconfig; then
        # macOS/BSD with ifconfig
        if [ -n "$interface_filter" ]; then
            ip=$(ifconfig "$interface_filter" 2>/dev/null | \
                 grep -oE 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | \
                 head -1 | awk '{print $2}')
            interface="$interface_filter"
        else
            # Try common interface names
            for iface in en0 en1 eth0 eth1 wlan0 wifi0; do
                ip=$(ifconfig "$iface" 2>/dev/null | \
                     grep -oE 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | \
                     head -1 | awk '{print $2}')
                if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
                    interface="$iface"
                    break
                fi
            done
        fi
    elif command_exists hostname; then
        # Fallback using hostname
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
        interface="unknown"
    fi
    
    # Validate IP
    if [ -z "$ip" ] || [ "$ip" = "127.0.0.1" ]; then
        echo "N/A"
        return 1
    fi
    
    # Format output
    if [ "$show_interface" = "yes" ] && [ -n "$interface" ] && [ "$interface" != "unknown" ]; then
        echo "$ip ($interface)"
    else
        echo "$ip"
    fi
}

# Get all LAN IPs
get_all_lan_ips() {
    local show_interface="$1"
    local ips=""
    
    if command_exists ip; then
        # Linux - get all non-loopback interfaces with IPs
        while IFS= read -r line; do
            local iface ip
            iface=$(echo "$line" | awk '{print $2}' | sed 's/://')
            ip=$(echo "$line" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
            
            if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
                if [ "$show_interface" = "yes" ]; then
                    ips="${ips}${ip} (${iface}) "
                else
                    ips="${ips}${ip} "
                fi
            fi
        done < <(ip addr show | grep -E '^[0-9]+:.*UP' | head -5)
    elif command_exists ifconfig; then
        # macOS/BSD
        for iface in $(ifconfig -l 2>/dev/null | tr ' ' '\n' | grep -E '^(en|eth|wlan|wifi)'); do
            local ip
            ip=$(ifconfig "$iface" 2>/dev/null | \
                 grep -oE 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | \
                 head -1 | awk '{print $2}')
            
            if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
                if [ "$show_interface" = "yes" ]; then
                    ips="${ips}${ip} (${iface}) "
                else
                    ips="${ips}${ip} "
                fi
            fi
        done
    fi
    
    if [ -n "$ips" ]; then
        echo "$ips" | sed 's/ $//'
    else
        echo "N/A"
    fi
}

# Main LAN IP function
main() {
    local format interface_filter show_interface
    
    format=$(get_tmux_option "@forceline_lan_ip_format" "primary")
    interface_filter=$(get_tmux_option "@forceline_lan_ip_interface" "")
    show_interface=$(get_tmux_option "@forceline_lan_ip_show_interface" "no")
    
    case "$format" in
        "primary")
            get_primary_lan_ip "$interface_filter" "$show_interface"
            ;;
        "all")
            get_all_lan_ips "$show_interface"
            ;;
        *)
            get_primary_lan_ip "$interface_filter" "$show_interface"
            ;;
    esac
}

# Execute if run directly
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi