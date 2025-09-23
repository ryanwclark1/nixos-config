#!/usr/bin/env bash
# Transient Status Notification Helper for tmux-forceline
# Convenient utility for triggering transient status messages

TRANSIENT_SCRIPT="/home/administrator/nixos-config/home/features/tmux/plugins/tmux-forceline/modules/transient/transient.sh"

# Show usage information
show_usage() {
    cat << EOF
Usage: $(basename "$0") <type> <message> [duration]

Types:
  success   - Show success message (green, ✅)
  warning   - Show warning message (orange, ⚠️) 
  error     - Show error message (red, ❌)
  info      - Show info message (blue, ℹ️)
  clear     - Clear all transient status messages

Examples:
  $(basename "$0") success "Build completed successfully" 5
  $(basename "$0") error "Build failed" 15
  $(basename "$0") warning "Deployment in progress" 30
  $(basename "$0") info "Cache cleared" 8
  $(basename "$0") clear

Duration: Optional, defaults vary by type (success: 5s, warning: 10s, error: 15s, info: 8s)
EOF
}

# Validate message type
validate_type() {
    local type="$1"
    case "$type" in
        success|warning|error|info|clear)
            return 0
            ;;
        *)
            echo "Error: Invalid type '$type'"
            echo "Valid types: success, warning, error, info, clear"
            return 1
            ;;
    esac
}

# Main function
main() {
    local type="${1:-}"
    local message="${2:-}"
    local duration="${3:-}"
    
    # Check if transient script exists
    if [[ ! -x "$TRANSIENT_SCRIPT" ]]; then
        echo "Error: Transient script not found or not executable: $TRANSIENT_SCRIPT"
        return 1
    fi
    
    # Show usage if no arguments
    if [[ $# -eq 0 ]]; then
        show_usage
        return 1
    fi
    
    # Validate type
    if ! validate_type "$type"; then
        echo
        show_usage
        return 1
    fi
    
    # Handle clear command
    if [[ "$type" == "clear" ]]; then
        "$TRANSIENT_SCRIPT" clear
        echo "Transient status cleared"
        return 0
    fi
    
    # Require message for other types
    if [[ -z "$message" ]]; then
        echo "Error: Message is required for type '$type'"
        echo
        show_usage
        return 1
    fi
    
    # Trigger transient status
    if [[ -n "$duration" ]]; then
        "$TRANSIENT_SCRIPT" "$type" "$message" "$duration"
        echo "Transient $type status set: $message (${duration}s)"
    else
        "$TRANSIENT_SCRIPT" "$type" "$message"
        echo "Transient $type status set: $message"
    fi
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi