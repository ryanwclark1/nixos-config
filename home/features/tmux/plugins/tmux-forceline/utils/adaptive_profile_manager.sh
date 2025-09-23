#!/usr/bin/env bash
# Adaptive Profile Manager for tmux-forceline v3.0
# Automatic configuration based on system context and usage patterns
# Implements intelligent defaults and profile switching

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

# Profile definitions
declare -A PROFILES=(
    ["laptop"]="Optimized for battery life and mobile usage"
    ["desktop"]="High performance configuration for workstations"
    ["server"]="Minimal resource usage for headless systems"
    ["development"]="Enhanced for development workflows"
    ["cloud"]="Optimized for cloud and virtualized environments"
    ["minimal"]="Bare minimum configuration for constrained systems"
    ["performance"]="Maximum performance regardless of resource usage"
    ["balanced"]="Balanced configuration for general use"
)

# Profile configurations
declare -A LAPTOP_CONFIG=(
    ["update_interval"]="5"
    ["cache_ttl"]="30"
    ["modules"]="session,hostname,datetime,battery,directory"
    ["network_modules"]="false"
    ["background_updates"]="true"
    ["visual_complexity"]="low"
    ["color_scheme"]="battery_aware"
    ["icons"]="minimal"
    ["animations"]="false"
)

declare -A DESKTOP_CONFIG=(
    ["update_interval"]="2"
    ["cache_ttl"]="15"
    ["modules"]="session,hostname,datetime,directory,cpu,memory,load,vcs"
    ["network_modules"]="true"
    ["background_updates"]="true"
    ["visual_complexity"]="high"
    ["color_scheme"]="full"
    ["icons"]="full"
    ["animations"]="true"
)

declare -A SERVER_CONFIG=(
    ["update_interval"]="10"
    ["cache_ttl"]="60"
    ["modules"]="session,hostname,datetime,uptime,load,memory"
    ["network_modules"]="false"
    ["background_updates"]="true"
    ["visual_complexity"]="minimal"
    ["color_scheme"]="monochrome"
    ["icons"]="none"
    ["animations"]="false"
)

declare -A DEVELOPMENT_CONFIG=(
    ["update_interval"]="3"
    ["cache_ttl"]="20"
    ["modules"]="session,hostname,datetime,directory,vcs,cpu,memory"
    ["network_modules"]="true"
    ["background_updates"]="true"
    ["visual_complexity"]="medium"
    ["color_scheme"]="development"
    ["icons"]="selective"
    ["animations"]="subtle"
)

declare -A CLOUD_CONFIG=(
    ["update_interval"]="15"
    ["cache_ttl"]="120"
    ["modules"]="session,hostname,datetime,uptime"
    ["network_modules"]="false"
    ["background_updates"]="false"
    ["visual_complexity"]="minimal"
    ["color_scheme"]="cloud"
    ["icons"]="minimal"
    ["animations"]="false"
)

declare -A MINIMAL_CONFIG=(
    ["update_interval"]="30"
    ["cache_ttl"]="300"
    ["modules"]="session,hostname"
    ["network_modules"]="false"
    ["background_updates"]="false"
    ["visual_complexity"]="none"
    ["color_scheme"]="basic"
    ["icons"]="none"
    ["animations"]="false"
)

declare -A PERFORMANCE_CONFIG=(
    ["update_interval"]="1"
    ["cache_ttl"]="5"
    ["modules"]="session,hostname,datetime,directory,cpu,memory,load,vcs,network,battery"
    ["network_modules"]="true"
    ["background_updates"]="true"
    ["visual_complexity"]="maximum"
    ["color_scheme"]="performance"
    ["icons"]="full"
    ["animations"]="true"
)

declare -A BALANCED_CONFIG=(
    ["update_interval"]="5"
    ["cache_ttl"]="30"
    ["modules"]="session,hostname,datetime,directory,cpu"
    ["network_modules"]="false"
    ["background_updates"]="true"
    ["visual_complexity"]="medium"
    ["color_scheme"]="balanced"
    ["icons"]="selective"
    ["animations"]="false"
)

# Current system context (populated by detection)
declare -A SYSTEM_CONTEXT=()
declare -A CURRENT_CONFIG=()

# Logging
log_profile() {
    local level="$1"
    local message="$2"
    echo "[$level] $message" >&2
}

# Load system context from detection
load_system_context() {
    local context_file="$1"
    
    if [[ -f "$context_file" ]]; then
        log_profile "INFO" "Loading system context from: $context_file"
        
        # Parse JSON context if available
        if command -v jq >/dev/null 2>&1; then
            local profile=$(jq -r '.system_context.recommendations.profile' "$context_file" 2>/dev/null || echo "")
            local system_type=$(jq -r '.system_context.environment.system_type' "$context_file" 2>/dev/null || echo "")
            local cpu_cores=$(jq -r '.system_context.hardware.cpu_cores' "$context_file" 2>/dev/null || echo "")
            local memory_mb=$(jq -r '.system_context.hardware.total_memory_mb' "$context_file" 2>/dev/null || echo "")
            local power_source=$(jq -r '.system_context.hardware.power_source' "$context_file" 2>/dev/null || echo "")
            
            SYSTEM_CONTEXT["profile"]="$profile"
            SYSTEM_CONTEXT["system_type"]="$system_type"
            SYSTEM_CONTEXT["cpu_cores"]="$cpu_cores"
            SYSTEM_CONTEXT["memory_mb"]="$memory_mb"
            SYSTEM_CONTEXT["power_source"]="$power_source"
        fi
    else
        log_profile "WARN" "Context file not found: $context_file"
        # Fall back to runtime detection
        detect_basic_context
    fi
}

# Basic runtime context detection
detect_basic_context() {
    log_profile "INFO" "Performing basic context detection..."
    
    # Simple system type detection
    local system_type="balanced"
    
    if [[ -d "/sys/class/power_supply" ]] && find /sys/class/power_supply -name "BAT*" -type d | grep -q .; then
        system_type="laptop"
    elif [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" ]]; then
        system_type="server"
    elif command -v git >/dev/null 2>&1 && (command -v nvim >/dev/null 2>&1 || command -v code >/dev/null 2>&1); then
        system_type="development"
    else
        system_type="desktop"
    fi
    
    SYSTEM_CONTEXT["system_type"]="$system_type"
    SYSTEM_CONTEXT["profile"]="$system_type"
}

# Get profile configuration
get_profile_config() {
    local profile="$1"
    
    case "$profile" in
        "laptop")
            for key in "${!LAPTOP_CONFIG[@]}"; do
                CURRENT_CONFIG["$key"]="${LAPTOP_CONFIG[$key]}"
            done
            ;;
        "desktop")
            for key in "${!DESKTOP_CONFIG[@]}"; do
                CURRENT_CONFIG["$key"]="${DESKTOP_CONFIG[$key]}"
            done
            ;;
        "server")
            for key in "${!SERVER_CONFIG[@]}"; do
                CURRENT_CONFIG["$key"]="${SERVER_CONFIG[$key]}"
            done
            ;;
        "development")
            for key in "${!DEVELOPMENT_CONFIG[@]}"; do
                CURRENT_CONFIG["$key"]="${DEVELOPMENT_CONFIG[$key]}"
            done
            ;;
        "cloud")
            for key in "${!CLOUD_CONFIG[@]}"; do
                CURRENT_CONFIG["$key"]="${CLOUD_CONFIG[$key]}"
            done
            ;;
        "minimal")
            for key in "${!MINIMAL_CONFIG[@]}"; do
                CURRENT_CONFIG["$key"]="${MINIMAL_CONFIG[$key]}"
            done
            ;;
        "performance")
            for key in "${!PERFORMANCE_CONFIG[@]}"; do
                CURRENT_CONFIG["$key"]="${PERFORMANCE_CONFIG[$key]}"
            done
            ;;
        "balanced"|*)
            for key in "${!BALANCED_CONFIG[@]}"; do
                CURRENT_CONFIG["$key"]="${BALANCED_CONFIG[$key]}"
            done
            ;;
    esac
}

# Apply profile configuration to tmux
apply_profile_configuration() {
    local profile="$1"
    local dry_run="${2:-false}"
    
    log_profile "INFO" "Applying profile configuration: $profile"
    
    get_profile_config "$profile"
    
    # Apply each configuration setting
    for key in "${!CURRENT_CONFIG[@]}"; do
        local tmux_option="@forceline_$key"
        local value="${CURRENT_CONFIG[$key]}"
        
        if [[ "$dry_run" == "true" ]]; then
            echo "tmux set-option -g \"$tmux_option\" \"$value\""
        else
            set_tmux_option "$tmux_option" "$value"
            log_profile "DEBUG" "Set $tmux_option = $value"
        fi
    done
    
    # Set profile marker
    if [[ "$dry_run" == "true" ]]; then
        echo "tmux set-option -g \"@forceline_active_profile\" \"$profile\""
        echo "tmux set-option -g \"@forceline_profile_applied\" \"$(date -Iseconds)\""
    else
        set_tmux_option "@forceline_active_profile" "$profile"
        set_tmux_option "@forceline_profile_applied" "$(date -Iseconds)"
    fi
    
    log_profile "INFO" "Profile configuration applied: $profile"
}

# Adaptive configuration adjustment
adjust_for_constraints() {
    local cpu_constraint="${1:-none}"
    local memory_constraint="${2:-none}"
    local battery_constraint="${3:-none}"
    
    log_profile "INFO" "Adjusting configuration for constraints: CPU=$cpu_constraint, Memory=$memory_constraint, Battery=$battery_constraint"
    
    # CPU constraint adjustments
    if [[ "$cpu_constraint" == "high" ]]; then
        CURRENT_CONFIG["update_interval"]=$((${CURRENT_CONFIG[update_interval]} * 3))
        CURRENT_CONFIG["cache_ttl"]=$((${CURRENT_CONFIG[cache_ttl]} * 2))
        CURRENT_CONFIG["background_updates"]="false"
        CURRENT_CONFIG["animations"]="false"
        log_profile "INFO" "Applied high CPU constraint adjustments"
    elif [[ "$cpu_constraint" == "medium" ]]; then
        CURRENT_CONFIG["update_interval"]=$((${CURRENT_CONFIG[update_interval]} * 2))
        CURRENT_CONFIG["animations"]="false"
        log_profile "INFO" "Applied medium CPU constraint adjustments"
    fi
    
    # Memory constraint adjustments
    if [[ "$memory_constraint" == "high" ]]; then
        CURRENT_CONFIG["cache_ttl"]=$((${CURRENT_CONFIG[cache_ttl]} / 2))
        CURRENT_CONFIG["modules"]="session,hostname,datetime"
        CURRENT_CONFIG["visual_complexity"]="minimal"
        log_profile "INFO" "Applied high memory constraint adjustments"
    elif [[ "$memory_constraint" == "medium" ]]; then
        CURRENT_CONFIG["visual_complexity"]="low"
        log_profile "INFO" "Applied medium memory constraint adjustments"
    fi
    
    # Battery constraint adjustments
    if [[ "$battery_constraint" != "none" ]]; then
        CURRENT_CONFIG["update_interval"]=$((${CURRENT_CONFIG[update_interval]} + 3))
        CURRENT_CONFIG["network_modules"]="false"
        CURRENT_CONFIG["visual_complexity"]="low"
        CURRENT_CONFIG["animations"]="false"
        log_profile "INFO" "Applied battery constraint adjustments"
    fi
}

# Profile recommendation based on context
recommend_profile() {
    local system_type="${SYSTEM_CONTEXT[system_type]:-balanced}"
    local cpu_cores="${SYSTEM_CONTEXT[cpu_cores]:-unknown}"
    local memory_mb="${SYSTEM_CONTEXT[memory_mb]:-unknown}"
    local power_source="${SYSTEM_CONTEXT[power_source]:-unknown}"
    
    log_profile "INFO" "Recommending profile for: type=$system_type, cpu=$cpu_cores, memory=${memory_mb}MB, power=$power_source"
    
    local recommended_profile="$system_type"
    
    # Override recommendations based on resource constraints
    if [[ "$memory_mb" != "unknown" && "$memory_mb" -lt 2048 ]] || 
       [[ "$cpu_cores" != "unknown" && "$cpu_cores" -le 2 ]]; then
        recommended_profile="minimal"
    elif [[ "$power_source" == "battery" ]]; then
        recommended_profile="laptop"
    elif [[ "$memory_mb" != "unknown" && "$memory_mb" -gt 32768 ]] && 
         [[ "$cpu_cores" != "unknown" && "$cpu_cores" -gt 16 ]]; then
        recommended_profile="performance"
    fi
    
    echo "$recommended_profile"
}

# Show current profile status
show_profile_status() {
    local current_profile=$(get_tmux_option "@forceline_active_profile" "none")
    local applied_time=$(get_tmux_option "@forceline_profile_applied" "never")
    
    echo "Current Profile Status:"
    echo "======================"
    echo "Active Profile: $current_profile"
    echo "Applied: $applied_time"
    echo ""
    
    if [[ "$current_profile" != "none" ]]; then
        echo "Profile Description: ${PROFILES[$current_profile]:-Unknown profile}"
        echo ""
        echo "Configuration:"
        for option in update_interval cache_ttl modules network_modules background_updates visual_complexity color_scheme icons animations; do
            local value=$(get_tmux_option "@forceline_$option" "not set")
            printf "  %-20s: %s\n" "$option" "$value"
        done
    fi
}

# List available profiles
list_profiles() {
    echo "Available Profiles:"
    echo "=================="
    echo ""
    
    for profile in "${!PROFILES[@]}"; do
        echo "📋 $profile"
        echo "   ${PROFILES[$profile]}"
        echo ""
    done
}

# Auto-apply best profile
auto_apply_profile() {
    local context_file="${1:-}"
    local dry_run="${2:-false}"
    
    log_profile "INFO" "Starting automatic profile application..."
    
    # Load system context
    if [[ -n "$context_file" ]]; then
        load_system_context "$context_file"
    else
        detect_basic_context
    fi
    
    # Get recommendation
    local recommended_profile=$(recommend_profile)
    log_profile "INFO" "Recommended profile: $recommended_profile"
    
    # Apply profile
    apply_profile_configuration "$recommended_profile" "$dry_run"
    
    echo "🎯 Applied profile: $recommended_profile"
    echo "📊 Profile: ${PROFILES[$recommended_profile]}"
}

# Interactive profile selection
interactive_profile_selection() {
    echo "🔧 Interactive Profile Selection"
    echo "================================"
    echo ""
    
    # Show current status
    show_profile_status
    echo ""
    
    # Show available profiles
    list_profiles
    
    # Get user selection
    echo "Available profiles: ${!PROFILES[*]}"
    echo ""
    read -p "Select a profile (or 'auto' for automatic): " selected_profile
    
    case "$selected_profile" in
        "auto")
            auto_apply_profile
            ;;
        "")
            echo "No profile selected, exiting."
            ;;
        *)
            if [[ -n "${PROFILES[$selected_profile]:-}" ]]; then
                apply_profile_configuration "$selected_profile"
                echo "✅ Applied profile: $selected_profile"
            else
                echo "❌ Unknown profile: $selected_profile"
                exit 1
            fi
            ;;
    esac
}

# Main execution
main() {
    local command=""
    local profile=""
    local context_file=""
    local dry_run="false"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            apply|status|list|auto|interactive)
                command="$1"
                shift
                ;;
            --profile|-p)
                profile="$2"
                shift 2
                ;;
            --context|-c)
                context_file="$2"
                shift 2
                ;;
            --dry-run|-n)
                dry_run="true"
                shift
                ;;
            --help|-h)
                cat << EOF
Adaptive Profile Manager for tmux-forceline v3.0

USAGE:
    $0 COMMAND [OPTIONS]

COMMANDS:
    apply PROFILE      Apply specific profile configuration
    auto              Automatically detect and apply best profile
    status            Show current profile status
    list              List available profiles
    interactive       Interactive profile selection

OPTIONS:
    -p, --profile PROFILE    Specify profile to apply
    -c, --context FILE       Use system context from file
    -n, --dry-run           Show commands without applying
    -h, --help              Show this help

PROFILES:
    laptop      - Battery optimized configuration
    desktop     - High performance workstation setup
    server      - Minimal headless configuration
    development - Enhanced for development workflows
    cloud       - Optimized for virtualized environments
    minimal     - Bare minimum for constrained systems
    performance - Maximum features regardless of resources
    balanced    - General purpose configuration

EXAMPLES:
    $0 auto                          # Auto-detect and apply
    $0 apply laptop                  # Apply laptop profile
    $0 auto --context context.json   # Use specific context
    $0 apply desktop --dry-run       # Show what would be applied
    $0 interactive                   # Interactive selection
EOF
                exit 0
                ;;
            *)
                if [[ -z "$profile" && "$command" == "apply" ]]; then
                    profile="$1"
                    shift
                else
                    log_profile "ERROR" "Unknown option: $1"
                    exit 1
                fi
                ;;
        esac
    done
    
    # Execute command
    case "$command" in
        "apply")
            if [[ -z "$profile" ]]; then
                log_profile "ERROR" "No profile specified for apply command"
                exit 1
            fi
            if [[ -z "${PROFILES[$profile]:-}" ]]; then
                log_profile "ERROR" "Unknown profile: $profile"
                exit 1
            fi
            apply_profile_configuration "$profile" "$dry_run"
            ;;
        "auto")
            auto_apply_profile "$context_file" "$dry_run"
            ;;
        "status")
            show_profile_status
            ;;
        "list")
            list_profiles
            ;;
        "interactive")
            interactive_profile_selection
            ;;
        "")
            log_profile "ERROR" "No command specified"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            log_profile "ERROR" "Unknown command: $command"
            exit 1
            ;;
    esac
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi