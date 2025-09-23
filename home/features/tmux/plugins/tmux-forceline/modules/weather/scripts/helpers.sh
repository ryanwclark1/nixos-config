#!/usr/bin/env bash

PATH="/usr/local/bin:$PATH:/usr/sbin"

# Source centralized tmux functions instead of local implementation
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"

if [[ -f "$UTILS_DIR/common.sh" ]]; then
    # shellcheck source=../../../utils/common.sh
    source "$UTILS_DIR/common.sh"
else
    # Fallback implementation if common.sh not available
    get_tmux_option() {
        local option="$1"
        local default="$2"
        tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
    }
    
    set_tmux_option() {
        local option="$1" 
        local value="$2"
        tmux set-option -gq "$option" "$value" 2>/dev/null
    }
    
    get_forceline_dir() {
        echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    }
fi

