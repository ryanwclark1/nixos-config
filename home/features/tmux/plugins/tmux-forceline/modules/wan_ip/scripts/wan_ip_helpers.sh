#!/usr/bin/env bash
# WAN IP Helper Functions for tmux-forceline v2.0
# Network IP detection with intelligent caching and fallback providers

# Default configurations
WAN_IP_CACHE_TTL="${FORCELINE_WAN_IP_CACHE_TTL:-900}"  # 15 minutes
WAN_IP_TIMEOUT="${FORCELINE_WAN_IP_TIMEOUT:-3}"        # 3 seconds
WAN_IP_PROVIDERS="${FORCELINE_WAN_IP_PROVIDERS:-ipify,icanhazip,checkip}"

# Cache directory setup
get_cache_dir() {
    local cache_dir="${TMUX_TMPDIR:-${TMPDIR:-/tmp}}/tmux-forceline"
    mkdir -p "$cache_dir" 2>/dev/null
    echo "$cache_dir"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get file modification time (cross-platform)
get_file_mtime() {
    local file="$1"
    
    if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == *"bsd"* ]]; then
        # macOS/BSD stat
        stat -f "%m" "$file" 2>/dev/null
    else
        # GNU stat (Linux)
        stat -c "%Y" "$file" 2>/dev/null
    fi
}

# Check if cache is valid
is_cache_valid() {
    local cache_file="$1"
    local ttl="$2"
    
    if [ ! -f "$cache_file" ]; then
        return 1
    fi
    
    local last_update current_time age
    last_update=$(get_file_mtime "$cache_file")
    current_time=$(date +%s)
    
    if [ -z "$last_update" ] || [ -z "$current_time" ]; then
        return 1
    fi
    
    age=$((current_time - last_update))
    [ "$age" -lt "$ttl" ]
}

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
    
    # Convert comma-separated list to array
    IFS=',' read -ra provider_array <<< "$providers"
    
    for provider in "${provider_array[@]}"; do
        provider=$(echo "$provider" | xargs)  # trim whitespace
        
        case "$provider" in
            "ipify")
                ip=$(get_wan_ip_ipify)
                ;;
            "icanhazip")
                ip=$(get_wan_ip_icanhazip)
                ;;
            "checkip")
                ip=$(get_wan_ip_checkip)
                ;;
            "httpbin")
                ip=$(get_wan_ip_httpbin)
                ;;
            "ident")
                ip=$(get_wan_ip_ident)
                ;;
        esac
        
        # Validate IP format (basic IPv4 check)
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
    
    local cache_dir cache_file wan_ip
    cache_dir=$(get_cache_dir)
    cache_file="$cache_dir/wan_ip.txt"
    
    # Check if we have curl
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
        # Cache the result
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