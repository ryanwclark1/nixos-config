#!/usr/bin/env bash
# Hardware Detection Utility for tmux-forceline
# Provides smart detection of system capabilities and hardware type

# Exit on any error for reliability
set -euo pipefail

# Global constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CACHE_DIR="${HOME}/.cache/tmux-forceline"
readonly CACHE_FILE="${CACHE_DIR}/hardware_info"
readonly CACHE_TTL=3600  # 1 hour cache

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

# Logging functions
log_debug() {
    [[ "${FL_DEBUG:-}" == "1" ]] && echo "[DEBUG] $*" >&2
}

log_info() {
    echo "[INFO] $*" >&2
}

log_error() {
    echo "[ERROR] $*" >&2
}

# Check if cache is valid
is_cache_valid() {
    [[ -f "$CACHE_FILE" ]] && [[ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0))) -lt $CACHE_TTL ]]
}

# Detect if system is a laptop
is_laptop() {
    # Multiple detection methods for reliability
    local laptop_indicators=0
    
    # Method 1: Check for battery presence
    if [[ -d /sys/class/power_supply/BAT* ]] 2>/dev/null; then
        ((laptop_indicators++))
        log_debug "Battery detected"
    fi
    
    # Method 2: Check DMI chassis type
    if [[ -r /sys/class/dmi/id/chassis_type ]]; then
        local chassis_type
        chassis_type=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo "")
        # Chassis types: 8=portable, 9=laptop, 10=notebook, 14=sub-notebook
        case "$chassis_type" in
            8|9|10|14) 
                ((laptop_indicators++))
                log_debug "Laptop chassis type detected: $chassis_type"
                ;;
        esac
    fi
    
    # Method 3: Check for laptop-specific devices
    if [[ -d /proc/acpi/button/lid ]] || [[ -r /sys/class/power_supply/AC* ]] 2>/dev/null; then
        ((laptop_indicators++))
        log_debug "Laptop-specific devices detected"
    fi
    
    # Method 4: Check systemd-detect-virt for container/VM
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        if systemd-detect-virt --quiet; then
            # In VM/container, assume it's not a laptop
            log_debug "Virtual environment detected"
            return 1
        fi
    fi
    
    # Require at least 2 indicators for confidence
    [[ $laptop_indicators -ge 2 ]]
}

# Detect available system capabilities
detect_capabilities() {
    local capabilities=()
    
    # Battery capability
    if is_laptop && [[ -d /sys/class/power_supply/BAT* ]] 2>/dev/null; then
        capabilities+=("battery")
    fi
    
    # Network capabilities
    if command -v ip >/dev/null 2>&1 || command -v ifconfig >/dev/null 2>&1; then
        capabilities+=("network")
        capabilities+=("lan_ip")
    fi
    
    # Internet connectivity
    if command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then
        capabilities+=("wan_ip")
    fi
    
    # VCS capabilities
    if command -v git >/dev/null 2>&1; then
        capabilities+=("vcs")
    fi
    
    # System monitoring
    capabilities+=("cpu" "memory" "load" "uptime" "hostname" "datetime")
    
    # Storage monitoring
    if command -v df >/dev/null 2>&1; then
        capabilities+=("disk_usage")
    fi
    
    printf '%s\n' "${capabilities[@]}"
}

# Detect OS type
detect_os() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "${ID:-unknown}"
    elif [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Get system architecture
get_architecture() {
    uname -m
}

# Generate hardware info
generate_hardware_info() {
    local is_laptop_result
    is_laptop_result=$(is_laptop && echo "true" || echo "false")
    
    cat > "$CACHE_FILE" << EOF
# Hardware information cache
# Generated: $(date -Iseconds)
IS_LAPTOP=$is_laptop_result
OS_TYPE=$(detect_os)
ARCHITECTURE=$(get_architecture)
CAPABILITIES=$(detect_capabilities | tr '\n' ',' | sed 's/,$//')
EOF
    
    log_info "Hardware detection completed: laptop=$is_laptop_result"
}

# Main function
main() {
    local action="${1:-detect}"
    
    case "$action" in
        "detect")
            if ! is_cache_valid; then
                log_debug "Cache invalid, regenerating hardware info"
                generate_hardware_info
            else
                log_debug "Using cached hardware info"
            fi
            
            # shellcheck source=/dev/null
            source "$CACHE_FILE"
            
            # Output based on requested information
            case "${2:-}" in
                "is_laptop") echo "$IS_LAPTOP" ;;
                "os_type") echo "$OS_TYPE" ;;
                "architecture") echo "$ARCHITECTURE" ;;
                "capabilities") echo "$CAPABILITIES" ;;
                *) 
                    echo "IS_LAPTOP=$IS_LAPTOP"
                    echo "OS_TYPE=$OS_TYPE"
                    echo "ARCHITECTURE=$ARCHITECTURE"
                    echo "CAPABILITIES=$CAPABILITIES"
                    ;;
            esac
            ;;
        "refresh")
            log_info "Forcing hardware detection refresh"
            rm -f "$CACHE_FILE"
            generate_hardware_info
            ;;
        "clear")
            log_info "Clearing hardware detection cache"
            rm -f "$CACHE_FILE"
            ;;
        *)
            log_error "Usage: $0 {detect|refresh|clear} [is_laptop|os_type|architecture|capabilities]"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"