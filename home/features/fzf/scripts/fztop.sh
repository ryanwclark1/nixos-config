#!/usr/bin/env bash

# Enhanced Process Manager with FZF
# Safe process management with confirmation and detailed information

set -euo pipefail

# Catppuccin Frappé colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly RESET='\033[0m'

# Global variables
declare -g PS_CMD="ps"
declare -g PS_OPTS=""
declare -g PREVIEW_CMD=""

# Helper functions
err() {
    printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2
}

info() {
    printf "${BLUE}[INFO]${RESET} %s\n" "$*"
}

warn() {
    printf "${YELLOW}[WARNING]${RESET} %s\n" "$*"
}

success() {
    printf "${GREEN}[SUCCESS]${RESET} %s\n" "$*"
}

has() {
    local verbose=false
    if [[ $1 == '-v' ]]; then
        verbose=true
        shift
    fi
    for cmd in "$@"; do
        if ! command -v "${cmd%% *}" &>/dev/null; then
            [[ "$verbose" == true ]] && err "$cmd not found"
            return 1
        fi
    done
}

# Initialize process command
init_ps_cmd() {
    # Check for different ps implementations and their capabilities
    if ps --version 2>/dev/null | grep -q "procps-ng"; then
        # GNU ps (Linux)
        PS_CMD="ps"
        PS_OPTS="axo pid,ppid,user,comm,args,etime,cpu,rss,vsz,stat --forest"
    elif ps -V 2>/dev/null | grep -q "BusyBox"; then
        # BusyBox ps (minimal)
        PS_CMD="ps"
        PS_OPTS="aux"
    else
        # BSD ps or other
        PS_CMD="ps"
        PS_OPTS="axo pid,ppid,user,comm,args,etime,cpu,rss,vsz,stat"
    fi
}

# Initialize preview command
init_preview_cmd() {
    PREVIEW_CMD='ps -fp {1} 2>/dev/null | tail -n +2 | while read line; do echo "Process Details:"; echo "$line"; done; echo; echo "Process Tree:"; pstree -p {1} 2>/dev/null || echo "pstree not available"; echo; echo "Open Files:"; lsof -p {1} 2>/dev/null | head -10 || echo "lsof not available or no open files"'
}

# Check if process is critical system process
is_critical_process() {
    local pid="$1"
    local comm="$2"
    local user="$3"
    
    # Check if it's init or kernel process
    [[ "$pid" == "1" ]] && return 0
    [[ "$pid" == "2" ]] && return 0
    
    # Check for critical system processes
    case "$comm" in
        systemd|init|kthreadd|ksoftirqd|migration|rcu_*|watchdog)
            return 0
            ;;
    esac
    
    # Check if it's a kernel thread (usually in brackets)
    [[ "$comm" =~ ^\[.*\]$ ]] && return 0
    
    # Check for root processes that are typically critical
    if [[ "$user" == "root" ]]; then
        case "$comm" in
            sshd|NetworkManager|systemd-*|dbus*|rsyslog)
                return 0
                ;;
        esac
    fi
    
    return 1
}

# Safe kill with confirmation
safe_kill() {
    local pid="$1"
    local signal="${2:-TERM}"
    local comm="$3"
    local user="$4"
    
    # Check if process still exists
    if ! kill -0 "$pid" 2>/dev/null; then
        warn "Process $pid no longer exists"
        return 1
    fi
    
    # Check if it's a critical process
    if is_critical_process "$pid" "$comm" "$user"; then
        err "Refusing to kill critical system process: $comm (PID: $pid)"
        warn "This appears to be a system process that should not be terminated"
        return 1
    fi
    
    # Check if it's our own process or parent
    local current_pid=$$
    local parent_pid=$(ps -o ppid= -p $current_pid | tr -d ' ')
    
    if [[ "$pid" == "$current_pid" ]] || [[ "$pid" == "$parent_pid" ]]; then
        err "Refusing to kill own process or parent"
        return 1
    fi
    
    # Get process info for confirmation
    local process_info
    process_info=$(ps -o pid,user,comm,args --no-headers -p "$pid" 2>/dev/null)
    
    if [[ -z "$process_info" ]]; then
        warn "Process $pid not found"
        return 1
    fi
    
    # Show confirmation
    echo
    warn "About to send SIG$signal to:"
    info "$process_info"
    echo
    
    if [[ "$signal" == "KILL" ]]; then
        err "WARNING: SIGKILL cannot be caught or ignored!"
        warn "The process will be terminated immediately without cleanup."
    fi
    
    printf "${YELLOW}Continue? (y/N): ${RESET}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if kill -s "$signal" "$pid" 2>/dev/null; then
            success "Sent SIG$signal to process $pid ($comm)"
            return 0
        else
            err "Failed to send signal to process $pid"
            return 1
        fi
    else
        info "Operation cancelled"
        return 1
    fi
}

# Show help
show_help() {
    cat << 'EOF'
Enhanced Process Manager with FZF

USAGE:
    fztop.sh [OPTIONS] [INITIAL_FILTER]

OPTIONS:
    -h, --help          Show this help message
    -a, --all           Show all processes (default: current user only)
    -u, --user USER     Show processes for specific user
    -f, --forest        Show process tree (if supported)

KEYBINDINGS:
    <Enter>             Show detailed process information
    <Ctrl-T>            Send SIGTERM (safe termination)
    <Ctrl-K>            Send SIGKILL (force kill) - USE WITH CAUTION
    <Ctrl-R>            Reload process list
    <Ctrl-S>            Toggle process sorting
    <Ctrl-L>            Toggle preview window
    <Esc>               Quit
    ?                   Show help in preview

FEATURES:
    - Real-time process monitoring
    - Safe kill operations with confirmations
    - Critical process protection
    - Detailed process information
    - Process tree visualization
    - Resource usage display

SAFETY FEATURES:
    - Prevents killing critical system processes
    - Confirmation prompts for all kill operations
    - Protection against killing own process
    - Clear warnings for dangerous operations

EXAMPLES:
    fztop.sh                    # Interactive process manager
    fztop.sh firefox            # Filter for firefox processes
    fztop.sh -u root            # Show root processes only
    fztop.sh -a                 # Show all processes
EOF
}

# Main function
main() {
    local initial_filter=""
    local show_all=false
    local target_user=""
    local use_forest=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -a|--all)
                show_all=true
                shift
                ;;
            -u|--user)
                target_user="$2"
                shift 2
                ;;
            -f|--forest)
                use_forest=true
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                err "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                initial_filter="$1"
                shift
                break
                ;;
        esac
    done
    
    # Check dependencies
    if ! has -v fzf ps; then
        err "This script requires fzf and ps to be installed"
        exit 1
    fi
    
    # Initialize commands
    init_ps_cmd
    init_preview_cmd
    
    # Modify ps command based on options
    if [[ "$show_all" == true ]]; then
        # Show all processes
        :
    elif [[ -n "$target_user" ]]; then
        PS_OPTS="$PS_OPTS --user=$target_user"
    else
        # Show only current user's processes
        PS_OPTS="$PS_OPTS --user=$(whoami)"
    fi
    
    if [[ "$use_forest" == true ]] && ps --forest --version &>/dev/null; then
        PS_OPTS="$PS_OPTS --forest"
    fi
    
    info "Starting process manager..."
    [[ -n "$initial_filter" ]] && info "Initial filter: $initial_filter"
    
    # Create header with color coding explanation
    local header="${BLUE}Process Manager${RESET} | ${GREEN}<Enter>${RESET} info | ${YELLOW}<Ctrl-T>${RESET} term | ${RED}<Ctrl-K>${RESET} kill | ${CYAN}?${RESET} help
${MAGENTA}Filter processes as you type${RESET}"
    
    # Main FZF command
    local selected
    selected=$(
        $PS_CMD $PS_OPTS 2>/dev/null | 
        fzf --ansi \
            --header="$header" \
            --header-lines=1 \
            --query="!fzf !ps !ssh !bash !zsh !fish !sh $initial_filter" \
            --preview="$PREVIEW_CMD" \
            --preview-window='right,60%,border-left,wrap' \
            --expect='ctrl-t,ctrl-k,ctrl-r' \
            --bind='ctrl-r:reload('"$PS_CMD $PS_OPTS"')' \
            --bind='ctrl-l:toggle-preview' \
            --bind='ctrl-s:toggle-sort' \
            --bind='esc:cancel' \
            --bind='?:preview:echo -e "KEYBINDINGS:\n\n<Enter> - Show detailed process info\n<Ctrl-T> - Send SIGTERM (graceful)\n<Ctrl-K> - Send SIGKILL (force)\n<Ctrl-R> - Reload process list\n<Ctrl-L> - Toggle preview\n<Ctrl-S> - Toggle sorting\n<Esc> - Quit\n\nSAFETY:\n- Critical processes are protected\n- Confirmations required for kills\n- Own process protection enabled"'
    ) || exit $?
    
    # Parse selection
    local key="${selected%%$'\n'*}"
    local process_line="${selected#*$'\n'}"
    
    [[ -z "$process_line" ]] && exit 0
    
    # Extract process information
    read -r pid ppid user comm args etime cpu rss vsz stat <<< "$process_line"
    
    case "$key" in
        ctrl-t)
            safe_kill "$pid" "TERM" "$comm" "$user"
            ;;
        ctrl-k)
            warn "SIGKILL is a forceful termination that cannot be caught!"
            safe_kill "$pid" "KILL" "$comm" "$user"
            ;;
        ctrl-r)
            # Reload is handled by FZF binding
            ;;
        "")
            # Show detailed information
            echo
            info "Process Information:"
            echo "PID: $pid"
            echo "PPID: $ppid"
            echo "User: $user"
            echo "Command: $comm"
            echo "Arguments: $args"
            echo "Runtime: $etime"
            echo "CPU%: $cpu"
            echo "RSS: $rss KB"
            echo "VSZ: $vsz KB"
            echo "Status: $stat"
            echo
            
            # Show process tree if available
            if command -v pstree &>/dev/null; then
                info "Process Tree:"
                pstree -p "$pid" 2>/dev/null || echo "No children"
            fi
            ;;
    esac
}

# Handle if sourced vs executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi