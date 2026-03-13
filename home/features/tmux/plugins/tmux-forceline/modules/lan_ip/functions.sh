#!/usr/bin/env bash
# Pure lan_ip functions for tmux-forceline
# Source this file — not meant to be executed directly
if [[ -z "${FL_VERSION:-}" ]]; then
    source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/pure_helpers.sh"
fi

# Get the primary LAN IP, optionally filtered by interface
get_primary_lan_ip() {
    local interface_filter="$1"
    local show_interface="$2"
    local ip interface

    if command_exists ip; then
        if [ -n "$interface_filter" ]; then
            ip=$(ip addr show "$interface_filter" 2>/dev/null | \
                 grep -oE 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | \
                 head -1 | awk '{print $2}')
            interface="$interface_filter"
        else
            interface=$(ip route | grep '^default' | head -1 | sed 's/.*dev \([^ ]*\).*/\1/')
            if [ -n "$interface" ]; then
                ip=$(ip addr show "$interface" 2>/dev/null | \
                     grep -oE 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | \
                     head -1 | awk '{print $2}')
            fi
        fi
    elif command_exists ifconfig; then
        if [ -n "$interface_filter" ]; then
            ip=$(ifconfig "$interface_filter" 2>/dev/null | \
                 grep -oE 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | \
                 head -1 | awk '{print $2}')
            interface="$interface_filter"
        else
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
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
        interface="unknown"
    fi

    if [ -z "${ip:-}" ] || [ "${ip:-}" = "127.0.0.1" ]; then
        echo "N/A"
        return 1
    fi

    if [ "$show_interface" = "yes" ] && [ -n "${interface:-}" ] && [ "${interface:-}" != "unknown" ]; then
        echo "$ip ($interface)"
    else
        echo "$ip"
    fi
}

# Get all non-loopback LAN IPs
get_all_lan_ips() {
    local show_interface="$1"
    local ips=""

    if command_exists ip; then
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
