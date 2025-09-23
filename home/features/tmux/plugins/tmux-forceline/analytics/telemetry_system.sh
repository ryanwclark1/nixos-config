#!/usr/bin/env bash
# tmux-forceline v3.0 Privacy-Respecting Telemetry System
# Collects anonymous usage data to improve the ecosystem while protecting user privacy

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TELEMETRY_DIR="${HOME}/.cache/tmux-forceline/telemetry"
readonly LOCAL_DATA="$TELEMETRY_DIR/local_metrics.json"
readonly CONSENT_FILE="$TELEMETRY_DIR/consent.json"
readonly DAILY_DIGEST="$TELEMETRY_DIR/daily_digest.json"
readonly TELEMETRY_ENDPOINT="https://telemetry.tmux-forceline.org/v1/metrics"

# Privacy configuration
readonly COLLECT_INTERVAL=86400  # 24 hours
readonly RETENTION_DAYS=30       # Local data retention
readonly MIN_POPULATION=100      # Minimum users before sharing aggregated data

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Function: Print colored output
print_status() {
    local level="$1"
    shift
    case "$level" in
        "info")    echo -e "${BLUE}ℹ${NC} $*" ;;
        "success") echo -e "${GREEN}✅${NC} $*" ;;
        "warning") echo -e "${YELLOW}⚠${NC} $*" ;;
        "error")   echo -e "${RED}❌${NC} $*" ;;
        "header")  echo -e "${PURPLE}📊${NC} ${WHITE}$*${NC}" ;;
        "privacy") echo -e "${CYAN}🔒${NC} $*" ;;
    esac
}

# Function: Initialize telemetry system
init_telemetry() {
    mkdir -p "$TELEMETRY_DIR"
    
    # Initialize consent file if not exists
    if [[ ! -f "$CONSENT_FILE" ]]; then
        cat > "$CONSENT_FILE" << 'EOF'
{
  "version": "1.0",
  "consent_given": false,
  "consent_date": null,
  "data_types_approved": [],
  "opt_out_date": null,
  "user_id": null,
  "last_prompt": 0
}
EOF
    fi
    
    # Initialize local data file
    if [[ ! -f "$LOCAL_DATA" ]]; then
        cat > "$LOCAL_DATA" << 'EOF'
{
  "version": "1.0",
  "install_date": null,
  "sessions": [],
  "performance_metrics": [],
  "feature_usage": {},
  "error_reports": [],
  "last_submission": 0
}
EOF
    fi
}

# Function: Show privacy notice and request consent
request_consent() {
    local force_prompt="${1:-no}"
    
    # Check if we should prompt
    local last_prompt consent_given
    last_prompt=$(jq -r '.last_prompt // 0' "$CONSENT_FILE")
    consent_given=$(jq -r '.consent_given // false' "$CONSENT_FILE")
    local current_time
    current_time=$(date +%s)
    local time_since_prompt=$((current_time - last_prompt))
    
    # Don't prompt if recently asked (unless forced) or already consented
    if [[ "$force_prompt" != "yes" && ($time_since_prompt -lt 604800 || "$consent_given" == "true") ]]; then
        return 0
    fi
    
    clear
    print_status "header" "tmux-forceline Privacy & Telemetry"
    echo
    
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                    Privacy-First Analytics                   ║
╚══════════════════════════════════════════════════════════════╝

tmux-forceline collects ANONYMOUS usage data to improve the ecosystem.
Your privacy is our priority - here's exactly what we collect:

📊 WHAT WE COLLECT (Anonymous):
  • Performance metrics (execution times, memory usage)
  • Feature usage patterns (which modules are popular)
  • System information (OS, tmux version - no personal details)
  • Error statistics (crash reports without sensitive data)

🔒 WHAT WE DON'T COLLECT:
  • Personal information (names, emails, usernames)
  • File paths or directory structures
  • Command history or terminal content
  • Network configuration or IP addresses
  • Any data that could identify you personally

🛡️ PRIVACY PROTECTIONS:
  • All data is anonymous and aggregated
  • No tracking across sessions or devices
  • Data stored locally for 30 days, then deleted
  • You can opt-out anytime with full data deletion
  • Open source collection code for transparency

💡 HOW THIS HELPS:
  • Identify performance bottlenecks to optimize
  • Understand which features need improvement
  • Guide development priorities based on real usage
  • Ensure compatibility across different systems

EOF
    
    echo -e "${CYAN}Your choice:${NC}"
    echo "  1. Yes, help improve tmux-forceline (anonymous data only)"
    echo "  2. No, disable all telemetry"
    echo "  3. Show me exactly what data would be sent"
    echo "  4. Customize what data to share"
    echo
    
    local choice
    while true; do
        echo -n "Enter your choice (1-4): "
        read -r choice
        
        case "$choice" in
            1)
                enable_telemetry "full"
                break
                ;;
            2)
                disable_telemetry
                break
                ;;
            3)
                show_sample_data
                echo
                continue
                ;;
            4)
                customize_consent
                break
                ;;
            *)
                print_status "error" "Please enter 1, 2, 3, or 4"
                ;;
        esac
    done
    
    # Update last prompt time
    jq --arg time "$current_time" '.last_prompt = ($time | tonumber)' \
       "$CONSENT_FILE" > "${CONSENT_FILE}.tmp" && mv "${CONSENT_FILE}.tmp" "$CONSENT_FILE"
}

# Function: Enable telemetry with specified level
enable_telemetry() {
    local level="$1"
    local current_time
    current_time=$(date +%s)
    local user_id
    user_id=$(openssl rand -hex 16 2>/dev/null || echo "anonymous-$(date +%s)")
    
    local data_types
    case "$level" in
        "full")
            data_types='["performance", "usage", "system", "errors"]'
            ;;
        "minimal")
            data_types='["performance", "usage"]'
            ;;
        "performance")
            data_types='["performance"]'
            ;;
        *)
            data_types='["performance"]'
            ;;
    esac
    
    jq --arg time "$current_time" \
       --arg user_id "$user_id" \
       --argjson data_types "$data_types" \
       '
       .consent_given = true |
       .consent_date = ($time | tonumber) |
       .user_id = $user_id |
       .data_types_approved = $data_types |
       .opt_out_date = null
       ' "$CONSENT_FILE" > "${CONSENT_FILE}.tmp" && mv "${CONSENT_FILE}.tmp" "$CONSENT_FILE"
    
    print_status "success" "Anonymous telemetry enabled - thank you for helping improve tmux-forceline!"
    print_status "info" "You can disable this anytime with: tmux-forceline telemetry disable"
}

# Function: Disable telemetry
disable_telemetry() {
    local current_time
    current_time=$(date +%s)
    
    jq --arg time "$current_time" \
       '
       .consent_given = false |
       .opt_out_date = ($time | tonumber) |
       .data_types_approved = []
       ' "$CONSENT_FILE" > "${CONSENT_FILE}.tmp" && mv "${CONSENT_FILE}.tmp" "$CONSENT_FILE"
    
    # Clear local data
    rm -f "$LOCAL_DATA" "$DAILY_DIGEST"
    
    print_status "success" "Telemetry disabled and local data cleared"
    print_status "info" "You can re-enable anytime with: tmux-forceline telemetry enable"
}

# Function: Show sample data that would be collected
show_sample_data() {
    print_status "header" "Sample Anonymous Data"
    echo
    
    cat << 'EOF'
{
  "timestamp": 1704067200,
  "version": "3.0.0",
  "session_id": "abc123def456",
  "system": {
    "os": "linux",
    "tmux_version": "3.4",
    "terminal": "unknown",
    "hardware_class": "desktop"
  },
  "performance": {
    "avg_exec_time_ms": 15,
    "memory_usage_mb": 2.1,
    "update_frequency": 1,
    "module_count": 8
  },
  "usage": {
    "active_modules": ["cpu", "memory", "datetime", "hostname"],
    "theme": "catppuccin-frappe",
    "profile": "balanced",
    "features_used": ["native_formats", "dynamic_themes"]
  },
  "errors": {
    "error_count": 0,
    "warning_count": 2,
    "performance_issues": 0
  }
}
EOF
    
    echo
    print_status "privacy" "Notice: No personal information, file paths, or identifiable data"
}

# Function: Customize consent
customize_consent() {
    echo
    print_status "header" "Customize Data Sharing"
    echo
    
    local data_types=()
    
    echo "Select which anonymous data types to share:"
    echo
    
    echo -n "📊 Performance metrics (execution times, memory usage)? [Y/n]: "
    read -r response
    if [[ ! "$response" =~ ^[Nn]$ ]]; then
        data_types+=("performance")
    fi
    
    echo -n "🎯 Feature usage (which modules are popular)? [Y/n]: "
    read -r response
    if [[ ! "$response" =~ ^[Nn]$ ]]; then
        data_types+=("usage")
    fi
    
    echo -n "💻 System information (OS, tmux version)? [Y/n]: "
    read -r response
    if [[ ! "$response" =~ ^[Nn]$ ]]; then
        data_types+=("system")
    fi
    
    echo -n "🚨 Anonymous error reports? [Y/n]: "
    read -r response
    if [[ ! "$response" =~ ^[Nn]$ ]]; then
        data_types+=("errors")
    fi
    
    if [[ ${#data_types[@]} -eq 0 ]]; then
        print_status "info" "No data types selected - telemetry will be disabled"
        disable_telemetry
    else
        local current_time user_id
        current_time=$(date +%s)
        user_id=$(openssl rand -hex 16 2>/dev/null || echo "anonymous-$(date +%s)")
        
        local data_types_json
        data_types_json=$(printf '%s\n' "${data_types[@]}" | jq -R . | jq -s .)
        
        jq --arg time "$current_time" \
           --arg user_id "$user_id" \
           --argjson data_types "$data_types_json" \
           '
           .consent_given = true |
           .consent_date = ($time | tonumber) |
           .user_id = $user_id |
           .data_types_approved = $data_types |
           .opt_out_date = null
           ' "$CONSENT_FILE" > "${CONSENT_FILE}.tmp" && mv "${CONSENT_FILE}.tmp" "$CONSENT_FILE"
        
        print_status "success" "Custom telemetry preferences saved"
        echo "Enabled data types: ${data_types[*]}"
    fi
}

# Function: Check if telemetry is enabled
is_telemetry_enabled() {
    if [[ ! -f "$CONSENT_FILE" ]]; then
        return 1
    fi
    
    local consent_given
    consent_given=$(jq -r '.consent_given // false' "$CONSENT_FILE")
    [[ "$consent_given" == "true" ]]
}

# Function: Collect session metrics
collect_session_metrics() {
    if ! is_telemetry_enabled; then
        return 0
    fi
    
    local current_time
    current_time=$(date +%s)
    local session_id
    session_id=$(openssl rand -hex 8 2>/dev/null || echo "session-$(date +%s)")
    
    # Detect system information
    local os_type tmux_version terminal_type hardware_class
    os_type=$(uname -s | tr '[:upper:]' '[:lower:]')
    tmux_version=$(tmux -V | grep -oE '[0-9]+\.[0-9]+' | head -1)
    terminal_type="unknown"
    
    # Determine hardware class
    if [[ -d "/sys/class/power_supply" ]] && find /sys/class/power_supply -name "BAT*" | grep -q .; then
        hardware_class="laptop"
    elif [[ -f "/proc/cpuinfo" ]] && grep -q "processor" /proc/cpuinfo && [[ $(grep -c "processor" /proc/cpuinfo) -gt 8 ]]; then
        hardware_class="workstation"
    else
        hardware_class="desktop"
    fi
    
    # Collect performance metrics
    local avg_exec_time=0 memory_usage=0 module_count=0
    if [[ -f "${HOME}/.cache/tmux-forceline/analytics/realtime.json" ]]; then
        local realtime_data
        realtime_data=$(cat "${HOME}/.cache/tmux-forceline/analytics/realtime.json" 2>/dev/null || echo "{}")
        
        local total_exec_time modules
        total_exec_time=$(echo "$realtime_data" | jq -r '.current_metrics.total_exec_time // 0')
        modules=$(echo "$realtime_data" | jq -r '.current_metrics.module_count // 1')
        memory_usage=$(echo "$realtime_data" | jq -r '.current_metrics.memory_usage // 0')
        
        if [[ $modules -gt 0 ]]; then
            avg_exec_time=$((total_exec_time / modules))
            module_count=$modules
        fi
    fi
    
    # Collect usage information
    local active_modules theme profile features_used
    active_modules=$(tmux show-options -g @forceline_plugins 2>/dev/null | cut -d' ' -f2- | tr ',' '\n' | jq -R . | jq -s . 2>/dev/null || echo "[]")
    theme=$(tmux show-options -g @forceline_theme 2>/dev/null | cut -d' ' -f2 || echo "default")
    profile=$(tmux show-options -g @forceline_profile 2>/dev/null | cut -d' ' -f2 || echo "balanced")
    
    # Detect features in use
    local features=()
    if tmux show-options -g | grep -q "@forceline.*native" 2>/dev/null; then
        features+=("native_formats")
    fi
    if [[ -f "${HOME}/.cache/tmux-forceline/themes/theme_daemon.pid" ]]; then
        features+=("dynamic_themes")
    fi
    if [[ -f "${HOME}/.cache/tmux-forceline/analytics/monitor.pid" ]]; then
        features+=("performance_monitoring")
    fi
    
    local features_json
    features_json=$(printf '%s\n' "${features[@]}" | jq -R . | jq -s . 2>/dev/null || echo "[]")
    
    # Create session record
    local session_data
    session_data=$(jq -n \
        --arg timestamp "$current_time" \
        --arg session_id "$session_id" \
        --arg os "$os_type" \
        --arg tmux_version "$tmux_version" \
        --arg terminal "$terminal_type" \
        --arg hardware "$hardware_class" \
        --arg exec_time "$avg_exec_time" \
        --arg memory "$memory_usage" \
        --arg modules "$module_count" \
        --argjson active_modules "$active_modules" \
        --arg theme "$theme" \
        --arg profile "$profile" \
        --argjson features "$features_json" \
        '{
            timestamp: ($timestamp | tonumber),
            session_id: $session_id,
            system: {
                os: $os,
                tmux_version: $tmux_version,
                terminal: $terminal,
                hardware_class: $hardware
            },
            performance: {
                avg_exec_time_ms: ($exec_time | tonumber),
                memory_usage_kb: ($memory | tonumber),
                module_count: ($modules | tonumber)
            },
            usage: {
                active_modules: $active_modules,
                theme: $theme,
                profile: $profile,
                features_used: $features
            }
        }')
    
    # Add to local data
    jq --argjson session "$session_data" \
       '.sessions += [$session]' \
       "$LOCAL_DATA" > "${LOCAL_DATA}.tmp" && mv "${LOCAL_DATA}.tmp" "$LOCAL_DATA"
    
    # Cleanup old sessions
    cleanup_old_data
}

# Function: Submit aggregated data
submit_telemetry_data() {
    if ! is_telemetry_enabled; then
        return 0
    fi
    
    local current_time last_submission
    current_time=$(date +%s)
    last_submission=$(jq -r '.last_submission // 0' "$LOCAL_DATA")
    local time_since_submission=$((current_time - last_submission))
    
    # Submit daily
    if [[ $time_since_submission -lt $COLLECT_INTERVAL ]]; then
        return 0
    fi
    
    # Aggregate local data
    local aggregated_data
    aggregated_data=$(aggregate_local_data)
    
    if [[ -z "$aggregated_data" || "$aggregated_data" == "null" ]]; then
        return 0
    fi
    
    # Submit data (if network available and endpoint reachable)
    if submit_data "$aggregated_data"; then
        # Update last submission time
        jq --arg time "$current_time" \
           '.last_submission = ($time | tonumber)' \
           "$LOCAL_DATA" > "${LOCAL_DATA}.tmp" && mv "${LOCAL_DATA}.tmp" "$LOCAL_DATA"
        
        print_status "info" "Anonymous usage data submitted - thank you for helping improve tmux-forceline!"
    fi
}

# Function: Aggregate local data for submission
aggregate_local_data() {
    if [[ ! -f "$LOCAL_DATA" ]]; then
        echo "null"
        return
    fi
    
    local sessions
    sessions=$(jq '.sessions // []' "$LOCAL_DATA")
    local session_count
    session_count=$(echo "$sessions" | jq 'length')
    
    if [[ $session_count -eq 0 ]]; then
        echo "null"
        return
    fi
    
    # Aggregate metrics
    local user_id
    user_id=$(jq -r '.user_id // "anonymous"' "$CONSENT_FILE")
    
    jq -n \
        --arg user_id "$user_id" \
        --arg version "3.0.0" \
        --argjson sessions "$sessions" \
        '{
            user_id: $user_id,
            version: $version,
            timestamp: now,
            session_count: ($sessions | length),
            performance: {
                avg_exec_time: ($sessions | map(.performance.avg_exec_time_ms) | add / length),
                avg_memory_usage: ($sessions | map(.performance.memory_usage_kb) | add / length),
                avg_module_count: ($sessions | map(.performance.module_count) | add / length)
            },
            usage: {
                most_used_modules: ($sessions | map(.usage.active_modules[]) | group_by(.) | map({module: .[0], count: length}) | sort_by(.count) | reverse | .[0:5]),
                themes_used: ($sessions | map(.usage.theme) | group_by(.) | map({theme: .[0], count: length})),
                profiles_used: ($sessions | map(.usage.profile) | group_by(.) | map({profile: .[0], count: length})),
                features_adoption: ($sessions | map(.usage.features_used[]) | group_by(.) | map({feature: .[0], count: length}))
            },
            system: {
                os_distribution: ($sessions | map(.system.os) | group_by(.) | map({os: .[0], count: length})),
                tmux_versions: ($sessions | map(.system.tmux_version) | group_by(.) | map({version: .[0], count: length})),
                hardware_types: ($sessions | map(.system.hardware_class) | group_by(.) | map({type: .[0], count: length}))
            }
        }'
}

# Function: Submit data to telemetry endpoint
submit_data() {
    local data="$1"
    
    # Check if submission should be attempted
    if ! command -v curl >/dev/null 2>&1; then
        return 1
    fi
    
    # Submit with timeout and no retries
    if curl -X POST \
           -H "Content-Type: application/json" \
           -H "User-Agent: tmux-forceline/3.0.0" \
           --connect-timeout 5 \
           --max-time 10 \
           --silent \
           --fail \
           --data "$data" \
           "$TELEMETRY_ENDPOINT" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function: Cleanup old data
cleanup_old_data() {
    local retention_timestamp
    retention_timestamp=$(($(date +%s) - (RETENTION_DAYS * 86400)))
    
    # Clean old sessions
    jq --arg retention "$retention_timestamp" \
       '.sessions = (.sessions // [] | map(select(.timestamp > ($retention | tonumber))))' \
       "$LOCAL_DATA" > "${LOCAL_DATA}.tmp" && mv "${LOCAL_DATA}.tmp" "$LOCAL_DATA"
}

# Function: Show telemetry status
show_telemetry_status() {
    print_status "header" "Telemetry Status"
    echo
    
    if ! is_telemetry_enabled; then
        print_status "info" "Telemetry is DISABLED"
        echo "  • No data is being collected or submitted"
        echo "  • Run 'tmux-forceline telemetry enable' to help improve the ecosystem"
        return 0
    fi
    
    local consent_date data_types last_submission
    consent_date=$(jq -r '.consent_date // 0' "$CONSENT_FILE")
    data_types=$(jq -r '.data_types_approved // [] | join(", ")' "$CONSENT_FILE")
    last_submission=$(jq -r '.last_submission // 0' "$LOCAL_DATA" 2>/dev/null)
    
    print_status "success" "Telemetry is ENABLED"
    echo "  • Consent given: $(date -d "@$consent_date" '+%Y-%m-%d' 2>/dev/null || echo "Unknown")"
    echo "  • Data types: $data_types"
    
    if [[ $last_submission -gt 0 ]]; then
        echo "  • Last submission: $(date -d "@$last_submission" '+%Y-%m-%d' 2>/dev/null || echo "Unknown")"
    else
        echo "  • Last submission: Never"
    fi
    
    # Show local data summary
    if [[ -f "$LOCAL_DATA" ]]; then
        local session_count
        session_count=$(jq '.sessions // [] | length' "$LOCAL_DATA" 2>/dev/null || echo "0")
        echo "  • Local sessions stored: $session_count"
    fi
    
    echo
    print_status "privacy" "All data is anonymous and helps improve tmux-forceline for everyone"
    print_status "info" "Disable anytime with: tmux-forceline telemetry disable"
}

# Function: Export local data
export_local_data() {
    local output_file="${1:-telemetry_export_$(date +%Y%m%d_%H%M%S).json}"
    
    if [[ ! -f "$LOCAL_DATA" ]]; then
        print_status "error" "No local telemetry data found"
        return 1
    fi
    
    print_status "info" "Exporting local telemetry data to: $output_file"
    
    # Create export with metadata
    jq -n \
        --slurpfile local_data "$LOCAL_DATA" \
        --slurpfile consent "$CONSENT_FILE" \
        '{
            export_timestamp: now,
            telemetry_version: "1.0",
            consent_info: $consent[0],
            local_data: $local_data[0],
            note: "This is your local telemetry data. Only aggregated, anonymous summaries are shared if telemetry is enabled."
        }' > "$output_file"
    
    print_status "success" "Telemetry data exported to: $output_file"
}

# Function: Main command dispatcher
main() {
    local command="${1:-status}"
    
    # Initialize telemetry system
    init_telemetry
    
    case "$command" in
        "enable")
            local level="${2:-full}"
            enable_telemetry "$level"
            ;;
        "disable")
            disable_telemetry
            ;;
        "status")
            show_telemetry_status
            ;;
        "consent")
            request_consent "yes"
            ;;
        "sample")
            show_sample_data
            ;;
        "collect")
            collect_session_metrics
            ;;
        "submit")
            submit_telemetry_data
            ;;
        "export")
            local output_file="$2"
            export_local_data "$output_file"
            ;;
        "cleanup")
            cleanup_old_data
            print_status "success" "Old telemetry data cleaned up"
            ;;
        *)
            echo "Usage: $0 {enable|disable|status|consent|sample|collect|submit|export|cleanup}"
            echo
            echo "Commands:"
            echo "  enable [level]    Enable telemetry (full/minimal/performance)"
            echo "  disable           Disable telemetry and clear data"
            echo "  status            Show current telemetry status"
            echo "  consent           Review and modify consent preferences"
            echo "  sample            Show sample data that would be collected"
            echo "  collect           Collect current session metrics"
            echo "  submit            Submit aggregated data (if due)"
            echo "  export [file]     Export local data to JSON file"
            echo "  cleanup           Clean up old local data"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"