#!/usr/bin/env bash
# Enhanced WAN IP script for tmux-forceline v3.0
# Combines simple IP detection with comprehensive geographical information
# Merges functionality from both wan_ip and ipwan modules

set -euo pipefail

# Global configuration
readonly SCRIPT_VERSION="3.0"
readonly CACHE_DURATION=900  # 15 minutes default
readonly DEFAULT_TIMEOUT=3
readonly MAX_RETRIES=3

# Source centralized tmux functions
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    # shellcheck source=../../../utils/common.sh
    source "$UTILS_DIR/common.sh"
    
    # Enhanced tmux option getter with WAN IP specific validation
    # This extends the centralized get_tmux_option with domain-specific validation
    get_tmux_option_validated() {
        local option="$1"
        local default="$2"
        local value
        value=$(get_tmux_option "$option" "$default")
        
        # Apply WAN IP specific validation rules
        case "$option" in
            "@forceline_wan_ip_cache_ttl")
                [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 60 ] && [ "$value" -le 3600 ] || value="900"
                ;;
            "@forceline_wan_ip_timeout")
                [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 1 ] && [ "$value" -le 10 ] || value="3"
                ;;
            "@forceline_wan_ip_format")
                [[ "$value" =~ ^(ip|geo|full|compact)$ ]] || value="ip"
                ;;
        esac
        
        echo "$value"
    }
    
    # Override get_tmux_option to use validated version for this module
    get_tmux_option() {
        get_tmux_option_validated "$@"
    }
else
    # Fallback implementation if common.sh not available
    get_tmux_option() {
        local option="$1"
        local default="$2"
        local value
        value=$(tmux show-option -gqv "$option" 2>/dev/null || echo "$default")
        
        # Apply same validation as enhanced version
        case "$option" in
            "@forceline_wan_ip_cache_ttl")
                [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 60 ] && [ "$value" -le 3600 ] || value="900"
                ;;
            "@forceline_wan_ip_timeout")
                [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 1 ] && [ "$value" -le 10 ] || value="3"
                ;;
            "@forceline_wan_ip_format")
                [[ "$value" =~ ^(ip|geo|full|compact)$ ]] || value="ip"
                ;;
        esac
        
        echo "$value"
    }
    
    # Provide get_forceline_dir for consistency if common.sh unavailable
    get_forceline_dir() {
        echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    }
fi

# Get cache directory
get_cache_dir() {
    local cache_dir="${TMUX_TMPDIR:-${TMPDIR:-/tmp}}/tmux-forceline"
    mkdir -p "$cache_dir" 2>/dev/null || {
        echo "/tmp" # Fallback
        return 1
    }
    echo "$cache_dir"
}

# Check if cached result is still valid
is_cache_valid() {
    local cache_file="$1"
    local max_age="$2"
    
    [[ -f "$cache_file" ]] || return 1
    
    local file_age
    if command -v stat >/dev/null 2>&1; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            file_age=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
        else
            file_age=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
        fi
    else
        return 1
    fi
    
    local current_time
    current_time=$(date +%s)
    
    [ $((current_time - file_age)) -lt "$max_age" ]
}

# Fetch simple WAN IP using multiple providers with fallback
fetch_simple_ip() {
    local timeout="$1"
    local providers="ipify.org,icanhazip.com,checkip.amazonaws.com,ifconfig.me"
    
    IFS=',' read -ra provider_array <<< "$providers"
    
    for provider in "${provider_array[@]}"; do
        provider=$(echo "$provider" | tr -d ' ')
        local ip
        if ip=$(timeout "$timeout" curl -s -f --max-time "$timeout" "https://$provider" 2>/dev/null); then
            # Validate IP format
            if [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                echo "$ip"
                return 0
            fi
        fi
    done
    
    return 1
}

# Fetch comprehensive geographical information from ipinfo.io
fetch_geo_info() {
    local timeout="$1"
    local json_data
    
    if ! json_data=$(timeout "$timeout" curl -s -f --max-time "$timeout" -H "Accept: application/json" "https://ipinfo.io" 2>/dev/null); then
        return 1
    fi
    
    # Parse JSON using either jq or awk
    if command -v jq >/dev/null 2>&1; then
        local ip city region country location postal timezone
        ip=$(echo "$json_data" | jq -r '.ip // "N/A"')
        city=$(echo "$json_data" | jq -r '.city // "N/A"')
        region=$(echo "$json_data" | jq -r '.region // "N/A"')
        country=$(echo "$json_data" | jq -r '.country // "N/A"')
        location=$(echo "$json_data" | jq -r '.loc // "N/A"')
        postal=$(echo "$json_data" | jq -r '.postal // "N/A"')
        timezone=$(echo "$json_data" | jq -r '.timezone // "N/A"')
    else
        # Fallback to awk parsing
        local ip city region country location postal timezone
        ip=$(echo "$json_data" | awk -F'"' '/"ip":/ {print $4}')
        city=$(echo "$json_data" | awk -F'"' '/"city":/ {print $4}')
        region=$(echo "$json_data" | awk -F'"' '/"region":/ {print $4}')
        country=$(echo "$json_data" | awk -F'"' '/"country":/ {print $4}')
        location=$(echo "$json_data" | awk -F'"' '/"loc":/ {print $4}')
        postal=$(echo "$json_data" | awk -F'"' '/"postal":/ {print $4}')
        timezone=$(echo "$json_data" | awk -F'"' '/"timezone":/ {print $4}')
    fi
    
    # Create JSON output
    cat << EOF
{
  "ip": "${ip:-N/A}",
  "city": "${city:-N/A}",
  "region": "${region:-N/A}",
  "country": "${country:-N/A}",
  "location": "${location:-N/A}",
  "postal": "${postal:-N/A}",
  "timezone": "${timezone:-N/A}"
}
EOF
}

# Format output based on requested format
format_output() {
    local format="$1"
    local data="$2"
    
    case "$format" in
        "ip")
            if command -v jq >/dev/null 2>&1; then
                echo "$data" | jq -r '.ip // "N/A"'
            else
                echo "$data" | awk -F'"' '/"ip":/ {print $4}' || echo "N/A"
            fi
            ;;
        "geo")
            if command -v jq >/dev/null 2>&1; then
                local city country
                city=$(echo "$data" | jq -r '.city // "N/A"')
                country=$(echo "$data" | jq -r '.country // "N/A"')
                echo "${city}, ${country}"
            else
                local city country
                city=$(echo "$data" | awk -F'"' '/"city":/ {print $4}')
                country=$(echo "$data" | awk -F'"' '/"country":/ {print $4}')
                echo "${city:-N/A}, ${country:-N/A}"
            fi
            ;;
        "compact")
            if command -v jq >/dev/null 2>&1; then
                local ip country
                ip=$(echo "$data" | jq -r '.ip // "N/A"')
                country=$(echo "$data" | jq -r '.country // "N/A"')
                echo "${ip} (${country})"
            else
                local ip country
                ip=$(echo "$data" | awk -F'"' '/"ip":/ {print $4}')
                country=$(echo "$data" | awk -F'"' '/"country":/ {print $4}')
                echo "${ip:-N/A} (${country:-N/A})"
            fi
            ;;
        "full")
            if command -v jq >/dev/null 2>&1; then
                echo "$data" | jq -r '"IP: " + (.ip // "N/A") + " | " + (.city // "N/A") + ", " + (.region // "N/A") + ", " + (.country // "N/A")'
            else
                local ip city region country
                ip=$(echo "$data" | awk -F'"' '/"ip":/ {print $4}')
                city=$(echo "$data" | awk -F'"' '/"city":/ {print $4}')
                region=$(echo "$data" | awk -F'"' '/"region":/ {print $4}')
                country=$(echo "$data" | awk -F'"' '/"country":/ {print $4}')
                echo "IP: ${ip:-N/A} | ${city:-N/A}, ${region:-N/A}, ${country:-N/A}"
            fi
            ;;
        *)
            echo "N/A"
            ;;
    esac
}

# Get cached or fresh WAN IP information
get_wan_info() {
    local cache_ttl="$1"
    local timeout="$2"
    local format="$3"
    
    local cache_dir cache_file
    cache_dir=$(get_cache_dir) || return 1
    cache_file="$cache_dir/wan_info.cache"
    
    # Return cached result if valid
    if is_cache_valid "$cache_file" "$cache_ttl"; then
        local cached_data
        cached_data=$(cat "$cache_file" 2>/dev/null)
        if [ -n "$cached_data" ]; then
            format_output "$format" "$cached_data"
            return 0
        fi
    fi
    
    # Fetch fresh data with retry logic
    local retry_count=0
    local wan_data
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        # Try geographical info first (more comprehensive)
        if wan_data=$(fetch_geo_info "$timeout" 2>/dev/null); then
            break
        fi
        
        # Fallback to simple IP if geo info fails
        if local simple_ip && simple_ip=$(fetch_simple_ip "$timeout" 2>/dev/null); then
            wan_data='{"ip":"'"$simple_ip"'","city":"N/A","region":"N/A","country":"N/A","location":"N/A","postal":"N/A","timezone":"N/A"}'
            break
        fi
        
        retry_count=$((retry_count + 1))
        [ $retry_count -lt $MAX_RETRIES ] && sleep 1
    done
    
    if [ -z "$wan_data" ]; then
        echo "N/A"
        return 1
    fi
    
    # Cache the result
    {
        echo "$wan_data"
    } > "$cache_file" 2>/dev/null || true
    
    format_output "$format" "$wan_data"
}

# Main function
main() {
    local format="${1:-}"
    
    # Get configuration from tmux options
    local cache_ttl timeout output_format
    
    cache_ttl=$(get_tmux_option "@forceline_wan_ip_cache_ttl" "$CACHE_DURATION")
    timeout=$(get_tmux_option "@forceline_wan_ip_timeout" "$DEFAULT_TIMEOUT")
    output_format=$(get_tmux_option "@forceline_wan_ip_format" "ip")
    
    # Override format if provided as parameter
    if [ -n "$format" ]; then
        output_format="$format"
    fi
    
    get_wan_info "$cache_ttl" "$timeout" "$output_format"
}

# Enhanced error handling for direct execution
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    # Trap errors and provide meaningful feedback
    trap 'echo "N/A" >&2; exit 1' ERR
    
    main "$@"
fi