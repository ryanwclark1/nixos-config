#!/usr/bin/env bash

# -----------------------------------------------------
# Clipboard Manager Wrapper Script
# Delegates to appropriate clipboard manager scripts
# -----------------------------------------------------
#
# This script maintains backward compatibility by delegating commands
# to the appropriate clipboard manager scripts:
# - UI commands (show, delete, clear) → rofi script
# - Non-UI commands (stats, daemon) → wayland core script
#
# See clipboard-manager.sh (wayland) for core functionality
# See rofi-clipboard-manager.sh (rofi) for UI functionality
# -----------------------------------------------------

set -euo pipefail

# Find scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find wayland core script (deployed location first, then source)
WAYLAND_SCRIPT=""
if [[ -f "$HOME/.local/bin/scripts/wayland/clipboard-manager.sh" ]]; then
    WAYLAND_SCRIPT="$HOME/.local/bin/scripts/wayland/clipboard-manager.sh"
elif [[ -f "$SCRIPT_DIR/../wayland/clipboard-manager.sh" ]]; then
    WAYLAND_SCRIPT="$SCRIPT_DIR/../wayland/clipboard-manager.sh"
elif command -v clipboard-manager.sh >/dev/null 2>&1; then
    WAYLAND_SCRIPT="$(command -v clipboard-manager.sh)"
fi

# Find rofi script (deployed location first, then source)
ROFI_SCRIPT=""
if [[ -f "$HOME/.config/desktop/window-managers/shared/scripts/rofi/rofi-clipboard-manager.sh" ]]; then
    ROFI_SCRIPT="$HOME/.config/desktop/window-managers/shared/scripts/rofi/rofi-clipboard-manager.sh"
elif [[ -f "$SCRIPT_DIR/../../window-managers/shared/launcher/scripts/rofi/rofi-clipboard-manager.sh" ]]; then
    ROFI_SCRIPT="$SCRIPT_DIR/../../window-managers/shared/launcher/scripts/rofi/rofi-clipboard-manager.sh"
fi

# Show usage information
usage() {
    cat << EOF
Clipboard Manager Wrapper Script

Usage: $0 [COMMAND]

Commands:
    show         Show clipboard history and select item (default)
    delete       Delete specific clipboard entries
    clear        Clear all clipboard history
    stats        Show clipboard statistics
    daemon start Start clipboard monitoring daemon
    daemon stop  Stop clipboard monitoring daemon
    help         Show this help

Examples:
    $0                    # Show clipboard history
    $0 show               # Same as above
    $0 delete             # Delete specific entries
    $0 clear              # Clear all history
    $0 stats              # Show statistics
    $0 daemon start       # Start monitoring daemon

Dependencies:
    - cliphist
    - wl-clipboard (wl-copy, wl-paste)
    - rofi (for UI commands: show, delete, clear)
EOF
}

# Main function
main() {
    local command="${1:-show}"

    # Handle help first
    if [[ "$command" == "help" || "$command" == "-h" || "$command" == "--help" ]]; then
        usage
        exit 0
    fi

    # Handle daemon and stats commands (non-UI, use wayland core script)
    if [[ "$command" == "daemon" || "$command" == "stats" || "$command" == "status" ]]; then
        if [[ -z "$WAYLAND_SCRIPT" || ! -f "$WAYLAND_SCRIPT" ]]; then
            echo "Error: Could not find clipboard-manager.sh core script" >&2
            echo "  Checked: $HOME/.local/bin/scripts/wayland/clipboard-manager.sh" >&2
            exit 1
        fi
        exec "$WAYLAND_SCRIPT" "$@"
    fi

    # Handle UI commands (show, delete, clear) - use rofi script
    if [[ "$command" == "show" || "$command" == "" || "$command" == "delete" || "$command" == "d" || "$command" == "clear" || "$command" == "wipe" || "$command" == "w" ]]; then
        if [[ -z "$ROFI_SCRIPT" || ! -f "$ROFI_SCRIPT" ]]; then
            echo "Error: Could not find rofi-clipboard-manager.sh script" >&2
            echo "  Checked: $HOME/.config/desktop/window-managers/shared/scripts/rofi/rofi-clipboard-manager.sh" >&2
            exit 1
        fi
        exec "$ROFI_SCRIPT" "$@"
    fi

    # Unknown command
    echo "Error: Unknown command '$command'" >&2
    echo "Use '$0 help' for usage information" >&2
    exit 1
}

# Run main function with all arguments
main "$@"
