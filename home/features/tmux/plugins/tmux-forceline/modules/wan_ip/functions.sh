#!/usr/bin/env bash
# Pure WAN IP functions for tmux-forceline
# Source this file — not meant to be executed directly

# Guard: skip if already loaded via source_helpers.sh (which includes common.sh)
if [[ -z "${FL_VERSION:-}" ]]; then
    source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/pure_helpers.sh"
fi

# Default configurations
WAN_IP_CACHE_TTL="${FORCELINE_WAN_IP_CACHE_TTL:-900}"
WAN_IP_TIMEOUT="${FORCELINE_WAN_IP_TIMEOUT:-3}"
WAN_IP_PROVIDERS="${FORCELINE_WAN_IP_PROVIDERS:-ipify,icanhazip,checkip}"

# WAN IP service providers
get_wan_ip_ipify() {
    curl --max-time "$WAN_IP_TIMEOUT" -s "https://api.ipify.org" 2>/dev/null
}

get_wan_ip_icanhazip() {
    curl --max-time "$WAN_IP_TIMEOUT" -s "https://icanhazip.com" 2>/dev/null | tr -d '\n'
}

get_wan_ip_checkip() {
    curl --max-time "$WAN_IP_TIMEOUT" -s "https://checkip.amazonaws.com" 2>/dev/null | tr -d '\n'
}

get_wan_ip_httpbin() {
    curl --max-time "$WAN_IP_TIMEOUT" -s "https://httpbin.org/ip" 2>/dev/null | \
        grep -o '"origin":"[^"]*"' | cut -d'"' -f4
}

get_wan_ip_ident() {
    curl --max-time "$WAN_IP_TIMEOUT" -s "https://ident.me" 2>/dev/null
}

# Try multiple providers with fallback
fetch_wan_ip() {
    local providers="$1"
    local ip=""

    IFS=',' read -ra provider_array <<< "$providers"

    for provider in "${provider_array[@]}"; do
        provider=$(echo "$provider" | xargs)

        case "$provider" in
            "ipify")     ip=$(get_wan_ip_ipify) ;;
            "icanhazip") ip=$(get_wan_ip_icanhazip) ;;
            "checkip")   ip=$(get_wan_ip_checkip) ;;
            "httpbin")   ip=$(get_wan_ip_httpbin) ;;
            "ident")     ip=$(get_wan_ip_ident) ;;
        esac

        if [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "$ip"
            return 0
        fi
    done

    return 1
}

# Get WAN IP with caching
get_wan_ip_cached() {
    local cache_ttl="$1"
    local timeout="$2"
    local providers="$3"
    local show_status="$4"

    WAN_IP_TIMEOUT="$timeout"

    local cache_dir cache_file wan_ip
    cache_dir=$(get_module_cache_dir "wan_ip")
    cache_file="$cache_dir/wan_ip.txt"

    if ! command_exists curl; then
        if [ "$show_status" = "yes" ]; then
            echo "MISSING:curl not available"
        else
            echo "N/A"
        fi
        return 1
    fi

    # Try to use cached value if valid
    if is_cache_valid "$cache_file" "$cache_ttl"; then
        wan_ip=$(cat "$cache_file" 2>/dev/null)
        if [ -n "$wan_ip" ] && [[ "$wan_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            if [ "$show_status" = "yes" ]; then
                echo "CACHED:$wan_ip"
            else
                echo "$wan_ip"
            fi
            return 0
        fi
    fi

    # Fetch new IP
    wan_ip=$(fetch_wan_ip "$providers")

    if [ -n "$wan_ip" ]; then
        echo "$wan_ip" > "$cache_file" 2>/dev/null
        if [ "$show_status" = "yes" ]; then
            echo "FRESH:$wan_ip"
        else
            echo "$wan_ip"
        fi
        return 0
    else
        # Try to use stale cache as fallback
        if [ -f "$cache_file" ]; then
            wan_ip=$(cat "$cache_file" 2>/dev/null)
            if [ -n "$wan_ip" ]; then
                if [ "$show_status" = "yes" ]; then
                    echo "STALE:$wan_ip"
                else
                    echo "$wan_ip"
                fi
                return 0
            fi
        fi

        if [ "$show_status" = "yes" ]; then
            echo "FAILED:Unable to fetch"
        else
            echo "N/A"
        fi
        return 1
    fi
}

# Get WAN IP color based on cache status
get_wan_ip_color() {
    local color_type="${1:-bg}"
    local cache_ttl="$2"
    local timeout="$3"
    local providers="$4"
    local online_fg="${5:-#{@fg\}}"
    local online_bg="${6:-#{@success\}}"
    local cached_fg="${7:-#{@fg\}}"
    local cached_bg="${8:-#{@surface_0\}}"
    local stale_fg="${9:-#{@base00\}}"
    local stale_bg="${10:-#{@warning\}}"
    local offline_fg="${11:-#{@base00\}}"
    local offline_bg="${12:-#{@error\}}"

    local ip_with_status status
    ip_with_status=$(get_wan_ip_cached "$cache_ttl" "$timeout" "$providers" "yes")
    status=$(echo "$ip_with_status" | cut -d':' -f1)

    case "$status" in
        "FRESH")   if [ "$color_type" = "fg" ]; then echo "$online_fg"; else echo "$online_bg"; fi ;;
        "CACHED")  if [ "$color_type" = "fg" ]; then echo "$cached_fg"; else echo "$cached_bg"; fi ;;
        "STALE")   if [ "$color_type" = "fg" ]; then echo "$stale_fg"; else echo "$stale_bg"; fi ;;
        "FAILED"|"MISSING") if [ "$color_type" = "fg" ]; then echo "$offline_fg"; else echo "$offline_bg"; fi ;;
        *)         if [ "$color_type" = "fg" ]; then echo "$cached_fg"; else echo "$cached_bg"; fi ;;
    esac
}

# Enhanced WAN IP with geographical information
get_wan_info_enhanced() {
    local cache_ttl="${1:-900}"
    local timeout="${2:-3}"
    local output_format="${3:-ip}"

    WAN_IP_TIMEOUT="$timeout"

    local cache_dir cache_file
    cache_dir=$(get_module_cache_dir "wan_ip_enhanced")
    cache_file="$cache_dir/wan_info.cache"

    # Return cached result if valid
    if is_cache_valid "$cache_file" "$cache_ttl"; then
        local cached_data
        cached_data=$(cat "$cache_file" 2>/dev/null)
        if [ -n "$cached_data" ]; then
            _format_wan_output "$output_format" "$cached_data"
            return 0
        fi
    fi

    # Fetch fresh data
    local wan_data
    if wan_data=$(timeout "$timeout" curl -s -f --max-time "$timeout" -H "Accept: application/json" "https://ipinfo.io" 2>/dev/null); then
        echo "$wan_data" > "$cache_file" 2>/dev/null || true
        _format_wan_output "$output_format" "$wan_data"
        return 0
    fi

    # Fallback to simple IP
    local simple_ip
    if simple_ip=$(fetch_wan_ip "$WAN_IP_PROVIDERS"); then
        wan_data='{"ip":"'"$simple_ip"'","city":"N/A","region":"N/A","country":"N/A"}'
        echo "$wan_data" > "$cache_file" 2>/dev/null || true
        _format_wan_output "$output_format" "$wan_data"
        return 0
    fi

    echo "N/A"
    return 1
}

_format_wan_output() {
    local format="$1"
    local data="$2"

    if command_exists jq; then
        case "$format" in
            "ip")      echo "$data" | jq -r '.ip // "N/A"' ;;
            "geo")     echo "$data" | jq -r '(.city // "N/A") + ", " + (.country // "N/A")' ;;
            "compact") echo "$data" | jq -r '(.ip // "N/A") + " (" + (.country // "N/A") + ")"' ;;
            "full")    echo "$data" | jq -r '"IP: " + (.ip // "N/A") + " | " + (.city // "N/A") + ", " + (.region // "N/A") + ", " + (.country // "N/A")' ;;
            *)         echo "$data" | jq -r '.ip // "N/A"' ;;
        esac
    else
        case "$format" in
            "ip")      echo "$data" | awk -F'"' '/"ip":/ {print $4}' ;;
            "geo")     local city country; city=$(echo "$data" | awk -F'"' '/"city":/ {print $4}'); country=$(echo "$data" | awk -F'"' '/"country":/ {print $4}'); echo "${city:-N/A}, ${country:-N/A}" ;;
            "compact") local ip country; ip=$(echo "$data" | awk -F'"' '/"ip":/ {print $4}'); country=$(echo "$data" | awk -F'"' '/"country":/ {print $4}'); echo "${ip:-N/A} (${country:-N/A})" ;;
            *)         echo "$data" | awk -F'"' '/"ip":/ {print $4}' ;;
        esac
    fi
}
