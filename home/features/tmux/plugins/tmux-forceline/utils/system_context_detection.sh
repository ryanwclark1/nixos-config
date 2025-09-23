#!/usr/bin/env bash
# System Context Detection for tmux-forceline v3.0
# Intelligent system analysis for adaptive configuration
# Detects hardware, usage patterns, and environment for optimal settings

set -euo pipefail

# Source centralized utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
else
    # Fallback tmux option functions
    get_tmux_option() {
        local option="$1"
        local default="$2"
        tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
    }
    
    set_tmux_option() {
        local option="$1"
        local value="$2"
        tmux set-option -gq "$option" "$value"
    }
fi

# System context categories
declare -A SYSTEM_CONTEXTS=(
    ["laptop"]="Battery-powered portable device with power constraints"
    ["desktop"]="High-performance workstation with ample resources"
    ["server"]="Headless system focused on stability and minimal resource usage"
    ["development"]="Development environment with IDE integration needs"
    ["embedded"]="Resource-constrained environment requiring minimal footprint"
    ["container"]="Containerized environment with namespace restrictions"
    ["remote"]="SSH/remote session with network considerations"
    ["cloud"]="Cloud instance with variable performance characteristics"
)

# Hardware detection results
declare -A HARDWARE_INFO=()
declare -A USAGE_PATTERNS=()
declare -A ENVIRONMENT_INFO=()
declare -A PERFORMANCE_CONSTRAINTS=()

# Configuration recommendations
declare -A CONFIG_RECOMMENDATIONS=()

# Utility functions
log_detection() {
    local level="$1"
    local message="$2"
    echo "[$level] $message" >&2
}

# CPU information detection
detect_cpu_info() {
    log_detection "INFO" "Detecting CPU information..."
    
    local cpu_cores=""
    local cpu_architecture=""
    local cpu_model=""
    
    # CPU core detection
    if [[ -f "/proc/cpuinfo" ]]; then
        cpu_cores=$(grep -c "^processor" /proc/cpuinfo 2>/dev/null || echo "unknown")
        cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs 2>/dev/null || echo "unknown")
    elif command -v sysctl >/dev/null 2>&1; then
        cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "unknown")
        cpu_model=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo "unknown")
    else
        cpu_cores="unknown"
        cpu_model="unknown"
    fi
    
    # Architecture detection
    cpu_architecture=$(uname -m 2>/dev/null || echo "unknown")
    
    HARDWARE_INFO["cpu_cores"]="$cpu_cores"
    HARDWARE_INFO["cpu_architecture"]="$cpu_architecture"
    HARDWARE_INFO["cpu_model"]="$cpu_model"
    
    log_detection "DEBUG" "CPU: $cpu_cores cores, $cpu_architecture, $cpu_model"
}

# Memory information detection
detect_memory_info() {
    log_detection "INFO" "Detecting memory information..."
    
    local total_memory=""
    local available_memory=""
    
    if [[ -f "/proc/meminfo" ]]; then
        total_memory=$(grep "MemTotal:" /proc/meminfo | awk '{print $2}' 2>/dev/null || echo "unknown")
        available_memory=$(grep "MemAvailable:" /proc/meminfo | awk '{print $2}' 2>/dev/null || echo "unknown")
        
        # Convert KB to MB for easier reading
        if [[ "$total_memory" != "unknown" ]]; then
            total_memory=$((total_memory / 1024))
        fi
        if [[ "$available_memory" != "unknown" ]]; then
            available_memory=$((available_memory / 1024))
        fi
    elif command -v sysctl >/dev/null 2>&1; then
        total_memory=$(sysctl -n hw.memsize 2>/dev/null || echo "unknown")
        if [[ "$total_memory" != "unknown" ]]; then
            total_memory=$((total_memory / 1024 / 1024))  # Convert bytes to MB
        fi
        available_memory="unknown"
    else
        total_memory="unknown"
        available_memory="unknown"
    fi
    
    HARDWARE_INFO["total_memory_mb"]="$total_memory"
    HARDWARE_INFO["available_memory_mb"]="$available_memory"
    
    log_detection "DEBUG" "Memory: ${total_memory}MB total, ${available_memory}MB available"
}

# Power source detection
detect_power_source() {
    log_detection "INFO" "Detecting power source..."
    
    local power_source="unknown"
    local battery_present="false"
    
    # Linux battery detection
    if [[ -d "/sys/class/power_supply" ]]; then
        if find /sys/class/power_supply -name "BAT*" -type d | grep -q .; then
            battery_present="true"
            power_source="battery"
            
            # Check if AC adapter is connected
            for adapter in /sys/class/power_supply/A{C,DP}*; do
                if [[ -f "$adapter/online" && "$(cat "$adapter/online" 2>/dev/null)" == "1" ]]; then
                    power_source="ac_adapter"
                    break
                fi
            done
        else
            power_source="ac_adapter"
        fi
    # macOS power detection
    elif command -v pmset >/dev/null 2>&1; then
        if pmset -g ps | grep -q "Battery Power"; then
            power_source="battery"
            battery_present="true"
        elif pmset -g ps | grep -q "AC Power"; then
            power_source="ac_adapter"
            # Check if battery exists
            if pmset -g batt | grep -q "InternalBattery"; then
                battery_present="true"
            fi
        fi
    fi
    
    HARDWARE_INFO["power_source"]="$power_source"
    HARDWARE_INFO["battery_present"]="$battery_present"
    
    log_detection "DEBUG" "Power: $power_source, battery: $battery_present"
}

# System type detection
detect_system_type() {
    log_detection "INFO" "Detecting system type..."
    
    local system_type="unknown"
    local virtualization="none"
    
    # Check for virtualization
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        virtualization=$(systemd-detect-virt 2>/dev/null || echo "none")
    elif [[ -f "/proc/1/environ" ]] && grep -q "container" /proc/1/environ 2>/dev/null; then
        virtualization="container"
    elif grep -q "hypervisor" /proc/cpuinfo 2>/dev/null; then
        virtualization="vm"
    fi
    
    # System type logic based on multiple factors
    if [[ "$virtualization" != "none" ]]; then
        if [[ "$virtualization" == "container" ]]; then
            system_type="container"
        else
            system_type="cloud"  # Assume cloud for VMs
        fi
    elif [[ "${HARDWARE_INFO[battery_present]}" == "true" ]]; then
        system_type="laptop"
    else
        # Check if this is a desktop vs server vs development environment
        local memory_mb="${HARDWARE_INFO[total_memory_mb]}"
        local cpu_cores="${HARDWARE_INFO[cpu_cores]}"
        local has_display=""
        
        # Display detection (desktop environment indicator)
        if [[ -n "$DISPLAY" || -n "$WAYLAND_DISPLAY" || -n "$XDG_SESSION_TYPE" ]]; then
            has_display="true"
        else
            has_display="false"
        fi
        
        # Development environment detection - check after usage patterns are set
        local dev_tools=""
        if [[ -n "${USAGE_PATTERNS[development_tools]:-}" ]]; then
            dev_tools="${USAGE_PATTERNS[development_tools]}"
        fi
        
        local has_dev_tools="false"
        if [[ "$dev_tools" == *"git"* && ( "$dev_tools" == *"nvim"* || "$dev_tools" == *"code"* ) ]]; then
            has_dev_tools="true"
        fi
        
        # Classification logic
        if [[ "$has_display" == "false" ]]; then
            system_type="server"
        elif [[ "$has_dev_tools" == "true" && "$memory_mb" != "unknown" && "$memory_mb" -gt 16384 ]]; then
            system_type="development"
        elif [[ "$memory_mb" != "unknown" && "$memory_mb" -gt 8192 ]] && 
             [[ "$cpu_cores" != "unknown" && "$cpu_cores" -gt 6 ]]; then
            system_type="desktop"
        else
            system_type="development"
        fi
    fi
    
    ENVIRONMENT_INFO["system_type"]="$system_type"
    ENVIRONMENT_INFO["virtualization"]="$virtualization"
    
    log_detection "DEBUG" "System type: $system_type, virtualization: $virtualization"
}

# Usage pattern detection
detect_usage_patterns() {
    log_detection "INFO" "Detecting usage patterns..."
    
    local terminal_multiplexer="tmux"
    local shell_type=""
    local development_tools=""
    local network_connectivity=""
    
    # Shell detection
    if [[ -n "${SHELL:-}" ]]; then
        shell_type=$(basename "$SHELL")
    else
        shell_type="unknown"
    fi
    
    # Development tools detection
    local dev_tools=()
    for tool in git nvim vim emacs code cursor docker kubectl npm pip cargo; do
        if command -v "$tool" >/dev/null 2>&1; then
            dev_tools+=("$tool")
        fi
    done
    development_tools=$(IFS=","; echo "${dev_tools[*]}")
    
    # Network connectivity check
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        network_connectivity="online"
    elif ping -c 1 1.1.1.1 >/dev/null 2>&1; then
        network_connectivity="online"
    else
        network_connectivity="offline"
    fi
    
    USAGE_PATTERNS["shell_type"]="$shell_type"
    USAGE_PATTERNS["development_tools"]="$development_tools"
    USAGE_PATTERNS["network_connectivity"]="$network_connectivity"
    
    log_detection "DEBUG" "Patterns: $shell_type shell, tools: $development_tools, network: $network_connectivity"
}

# Performance constraints detection
detect_performance_constraints() {
    log_detection "INFO" "Detecting performance constraints..."
    
    local cpu_constraint="none"
    local memory_constraint="none"
    local battery_constraint="none"
    local network_constraint="none"
    
    # CPU constraints
    local cpu_cores="${HARDWARE_INFO[cpu_cores]}"
    if [[ "$cpu_cores" != "unknown" && "$cpu_cores" -le 2 ]]; then
        cpu_constraint="high"
    elif [[ "$cpu_cores" != "unknown" && "$cpu_cores" -le 4 ]]; then
        cpu_constraint="medium"
    fi
    
    # Memory constraints
    local memory_mb="${HARDWARE_INFO[total_memory_mb]}"
    if [[ "$memory_mb" != "unknown" && "$memory_mb" -le 2048 ]]; then
        memory_constraint="high"
    elif [[ "$memory_mb" != "unknown" && "$memory_mb" -le 4096 ]]; then
        memory_constraint="medium"
    fi
    
    # Battery constraints
    if [[ "${HARDWARE_INFO[power_source]}" == "battery" ]]; then
        battery_constraint="medium"
        # Could enhance with actual battery level detection
    fi
    
    # Network constraints
    if [[ "${USAGE_PATTERNS[network_connectivity]}" == "offline" ]]; then
        network_constraint="high"
    elif [[ "${ENVIRONMENT_INFO[system_type]}" == "remote" ]]; then
        network_constraint="medium"
    fi
    
    PERFORMANCE_CONSTRAINTS["cpu"]="$cpu_constraint"
    PERFORMANCE_CONSTRAINTS["memory"]="$memory_constraint"
    PERFORMANCE_CONSTRAINTS["battery"]="$battery_constraint"
    PERFORMANCE_CONSTRAINTS["network"]="$network_constraint"
    
    log_detection "DEBUG" "Constraints: CPU=$cpu_constraint, Memory=$memory_constraint, Battery=$battery_constraint, Network=$network_constraint"
}

# Generate configuration recommendations
generate_recommendations() {
    log_detection "INFO" "Generating configuration recommendations..."
    
    local system_type="${ENVIRONMENT_INFO[system_type]}"
    local cpu_constraint="${PERFORMANCE_CONSTRAINTS[cpu]}"
    local memory_constraint="${PERFORMANCE_CONSTRAINTS[memory]}"
    local battery_constraint="${PERFORMANCE_CONSTRAINTS[battery]}"
    local network_constraint="${PERFORMANCE_CONSTRAINTS[network]}"
    
    # Base recommendations by system type
    case "$system_type" in
        "laptop")
            CONFIG_RECOMMENDATIONS["profile"]="laptop"
            CONFIG_RECOMMENDATIONS["update_interval"]="5"
            CONFIG_RECOMMENDATIONS["cache_ttl"]="30"
            CONFIG_RECOMMENDATIONS["modules"]="session,hostname,datetime,battery,directory,cpu"
            CONFIG_RECOMMENDATIONS["network_modules"]="false"
            CONFIG_RECOMMENDATIONS["background_updates"]="true"
            ;;
        "desktop")
            CONFIG_RECOMMENDATIONS["profile"]="desktop"
            CONFIG_RECOMMENDATIONS["update_interval"]="2"
            CONFIG_RECOMMENDATIONS["cache_ttl"]="15"
            CONFIG_RECOMMENDATIONS["modules"]="session,hostname,datetime,directory,cpu,memory,load"
            CONFIG_RECOMMENDATIONS["network_modules"]="true"
            CONFIG_RECOMMENDATIONS["background_updates"]="true"
            ;;
        "server")
            CONFIG_RECOMMENDATIONS["profile"]="server"
            CONFIG_RECOMMENDATIONS["update_interval"]="10"
            CONFIG_RECOMMENDATIONS["cache_ttl"]="60"
            CONFIG_RECOMMENDATIONS["modules"]="session,hostname,datetime,uptime,load,memory"
            CONFIG_RECOMMENDATIONS["network_modules"]="false"
            CONFIG_RECOMMENDATIONS["background_updates"]="true"
            ;;
        "development")
            CONFIG_RECOMMENDATIONS["profile"]="development"
            CONFIG_RECOMMENDATIONS["update_interval"]="3"
            CONFIG_RECOMMENDATIONS["cache_ttl"]="20"
            CONFIG_RECOMMENDATIONS["modules"]="session,hostname,datetime,directory,vcs,cpu,memory"
            CONFIG_RECOMMENDATIONS["network_modules"]="true"
            CONFIG_RECOMMENDATIONS["background_updates"]="true"
            ;;
        "container"|"cloud")
            CONFIG_RECOMMENDATIONS["profile"]="cloud"
            CONFIG_RECOMMENDATIONS["update_interval"]="15"
            CONFIG_RECOMMENDATIONS["cache_ttl"]="120"
            CONFIG_RECOMMENDATIONS["modules"]="session,hostname,datetime,uptime"
            CONFIG_RECOMMENDATIONS["network_modules"]="false"
            CONFIG_RECOMMENDATIONS["background_updates"]="false"
            ;;
        *)
            CONFIG_RECOMMENDATIONS["profile"]="balanced"
            CONFIG_RECOMMENDATIONS["update_interval"]="5"
            CONFIG_RECOMMENDATIONS["cache_ttl"]="30"
            CONFIG_RECOMMENDATIONS["modules"]="session,hostname,datetime,directory"
            CONFIG_RECOMMENDATIONS["network_modules"]="false"
            CONFIG_RECOMMENDATIONS["background_updates"]="true"
            ;;
    esac
    
    # Adjust based on constraints
    if [[ "$cpu_constraint" == "high" || "$memory_constraint" == "high" ]]; then
        CONFIG_RECOMMENDATIONS["update_interval"]=$((${CONFIG_RECOMMENDATIONS[update_interval]} * 2))
        CONFIG_RECOMMENDATIONS["cache_ttl"]=$((${CONFIG_RECOMMENDATIONS[cache_ttl]} * 2))
        CONFIG_RECOMMENDATIONS["modules"]="session,hostname,datetime"
        CONFIG_RECOMMENDATIONS["background_updates"]="false"
    fi
    
    if [[ "$battery_constraint" != "none" ]]; then
        CONFIG_RECOMMENDATIONS["update_interval"]=$((${CONFIG_RECOMMENDATIONS[update_interval]} + 2))
        CONFIG_RECOMMENDATIONS["network_modules"]="false"
    fi
    
    if [[ "$network_constraint" != "none" ]]; then
        CONFIG_RECOMMENDATIONS["network_modules"]="false"
    fi
    
    log_detection "INFO" "Recommendations generated for $system_type profile"
}

# Output system context report
generate_context_report() {
    local output_format="${1:-text}"
    local output_file="${2:-}"
    
    local report_content=""
    
    case "$output_format" in
        "json")
            report_content=$(cat << EOF
{
  "system_context": {
    "detection_time": "$(date -Iseconds)",
    "hardware": {
      "cpu_cores": "${HARDWARE_INFO[cpu_cores]}",
      "cpu_architecture": "${HARDWARE_INFO[cpu_architecture]}",
      "cpu_model": "${HARDWARE_INFO[cpu_model]}",
      "total_memory_mb": "${HARDWARE_INFO[total_memory_mb]}",
      "available_memory_mb": "${HARDWARE_INFO[available_memory_mb]}",
      "power_source": "${HARDWARE_INFO[power_source]}",
      "battery_present": "${HARDWARE_INFO[battery_present]}"
    },
    "environment": {
      "system_type": "${ENVIRONMENT_INFO[system_type]}",
      "virtualization": "${ENVIRONMENT_INFO[virtualization]}",
      "os_type": "$(uname -s)",
      "os_version": "$(uname -r)"
    },
    "usage_patterns": {
      "shell_type": "${USAGE_PATTERNS[shell_type]}",
      "development_tools": "${USAGE_PATTERNS[development_tools]}",
      "network_connectivity": "${USAGE_PATTERNS[network_connectivity]}"
    },
    "performance_constraints": {
      "cpu": "${PERFORMANCE_CONSTRAINTS[cpu]}",
      "memory": "${PERFORMANCE_CONSTRAINTS[memory]}",
      "battery": "${PERFORMANCE_CONSTRAINTS[battery]}",
      "network": "${PERFORMANCE_CONSTRAINTS[network]}"
    },
    "recommendations": {
      "profile": "${CONFIG_RECOMMENDATIONS[profile]}",
      "update_interval": "${CONFIG_RECOMMENDATIONS[update_interval]}",
      "cache_ttl": "${CONFIG_RECOMMENDATIONS[cache_ttl]}",
      "modules": "${CONFIG_RECOMMENDATIONS[modules]}",
      "network_modules": "${CONFIG_RECOMMENDATIONS[network_modules]}",
      "background_updates": "${CONFIG_RECOMMENDATIONS[background_updates]}"
    }
  }
}
EOF
)
            ;;
        "text"|*)
            report_content=$(cat << EOF
# System Context Detection Report

Generated: $(date)
System: $(uname -s) $(uname -r)

## Hardware Information
- CPU: ${HARDWARE_INFO[cpu_cores]} cores (${HARDWARE_INFO[cpu_architecture]})
- Model: ${HARDWARE_INFO[cpu_model]}
- Memory: ${HARDWARE_INFO[total_memory_mb]}MB total, ${HARDWARE_INFO[available_memory_mb]}MB available
- Power: ${HARDWARE_INFO[power_source]} (battery: ${HARDWARE_INFO[battery_present]})

## Environment Information
- System Type: ${ENVIRONMENT_INFO[system_type]}
- Virtualization: ${ENVIRONMENT_INFO[virtualization]}
- Context: ${SYSTEM_CONTEXTS[${ENVIRONMENT_INFO[system_type]}]:-Unknown system type}

## Usage Patterns
- Shell: ${USAGE_PATTERNS[shell_type]}
- Development Tools: ${USAGE_PATTERNS[development_tools]}
- Network: ${USAGE_PATTERNS[network_connectivity]}

## Performance Constraints
- CPU: ${PERFORMANCE_CONSTRAINTS[cpu]}
- Memory: ${PERFORMANCE_CONSTRAINTS[memory]}
- Battery: ${PERFORMANCE_CONSTRAINTS[battery]}
- Network: ${PERFORMANCE_CONSTRAINTS[network]}

## Configuration Recommendations

### Recommended Profile: ${CONFIG_RECOMMENDATIONS[profile]}

- Update Interval: ${CONFIG_RECOMMENDATIONS[update_interval]} seconds
- Cache TTL: ${CONFIG_RECOMMENDATIONS[cache_ttl]} seconds
- Recommended Modules: ${CONFIG_RECOMMENDATIONS[modules]}
- Network Modules: ${CONFIG_RECOMMENDATIONS[network_modules]}
- Background Updates: ${CONFIG_RECOMMENDATIONS[background_updates]}

### Profile Characteristics:
${SYSTEM_CONTEXTS[${CONFIG_RECOMMENDATIONS[profile]}]:-Balanced configuration for general use}

### Implementation Commands:
\`\`\`bash
# Apply recommended configuration
tmux set-option -g @forceline_profile "${CONFIG_RECOMMENDATIONS[profile]}"
tmux set-option -g @forceline_update_interval "${CONFIG_RECOMMENDATIONS[update_interval]}"
tmux set-option -g @forceline_cache_ttl "${CONFIG_RECOMMENDATIONS[cache_ttl]}"
tmux set-option -g @forceline_modules "${CONFIG_RECOMMENDATIONS[modules]}"
tmux set-option -g @forceline_network_modules "${CONFIG_RECOMMENDATIONS[network_modules]}"
tmux set-option -g @forceline_background_updates "${CONFIG_RECOMMENDATIONS[background_updates]}"
\`\`\`
EOF
)
            ;;
    esac
    
    if [[ -n "$output_file" ]]; then
        echo "$report_content" > "$output_file"
        log_detection "INFO" "Context report saved to: $output_file"
    else
        echo "$report_content"
    fi
}

# Main detection process
main() {
    local output_format="text"
    local output_file=""
    local verbose="false"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --format|-f)
                output_format="$2"
                shift 2
                ;;
            --output|-o)
                output_file="$2"
                shift 2
                ;;
            --verbose|-v)
                verbose="true"
                shift
                ;;
            --help|-h)
                cat << EOF
System Context Detection for tmux-forceline v3.0

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -f, --format FORMAT    Output format: text, json (default: text)
    -o, --output FILE      Save report to file
    -v, --verbose          Verbose logging
    -h, --help            Show this help

EXAMPLES:
    $0                     Generate text report
    $0 -f json -o context.json  Generate JSON report
    $0 -v                  Verbose detection process
EOF
                exit 0
                ;;
            *)
                log_detection "ERROR" "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    log_detection "INFO" "Starting system context detection..."
    
    # Run all detection functions in proper order
    detect_cpu_info
    detect_memory_info
    detect_power_source
    detect_usage_patterns  # Must come before system_type for dev tools detection
    detect_system_type
    detect_performance_constraints
    generate_recommendations
    
    # Generate report
    generate_context_report "$output_format" "$output_file"
    
    log_detection "INFO" "System context detection complete"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi