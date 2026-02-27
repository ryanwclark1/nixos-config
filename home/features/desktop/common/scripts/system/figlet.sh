#!/usr/bin/env bash

# ASCII Art Generator with Clipboard Support
# Creates ASCII art from text input using figlet and copies to clipboard

set -euo pipefail

# Configuration
FIGLET_FONT="${FIGLET_FONT:-smslant}"
FIGLET_FILE="${HOME}/figlet.txt"

# Check dependencies
check_dependencies() {
    local missing=()

    if ! command -v figlet >/dev/null 2>&1; then
        missing+=("figlet")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Missing required dependencies: ${missing[*]}" >&2
        echo "On NixOS: add 'figlet' to your packages" >&2
        exit 1
    fi
}

# Generate ASCII art
generate_ascii_art() {
    local text="$1"
    local font="${2:-$FIGLET_FONT}"

    figlet -f "$font" "$text" 2>/dev/null || {
        echo "Error: Failed to generate ASCII art" >&2
        return 1
    }
}

# Copy to clipboard with fallbacks
copy_to_clipboard() {
    local content="$1"
    local copied=false

    # Try Wayland clipboard first (wl-copy)
    if command -v wl-copy >/dev/null 2>&1; then
        if echo "$content" | wl-copy 2>/dev/null; then
            echo "Text copied to clipboard via wl-copy (Wayland)"
            copied=true
        fi
    fi

    # Try X11 clipboard if Wayland failed or isn't available
    if [[ "$copied" == false ]] && command -v xclip >/dev/null 2>&1; then
        if echo "$content" | xclip -selection clipboard 2>/dev/null; then
            echo "Text copied to clipboard via xclip (X11)"
            copied=true
        fi
    fi

    # Try xsel as another X11 option
    if [[ "$copied" == false ]] && command -v xsel >/dev/null 2>&1; then
        if echo "$content" | xsel --clipboard --input 2>/dev/null; then
            echo "Text copied to clipboard via xsel (X11)"
            copied=true
        fi
    fi

    # Try pbcopy for macOS compatibility
    if [[ "$copied" == false ]] && command -v pbcopy >/dev/null 2>&1; then
        if echo "$content" | pbcopy 2>/dev/null; then
            echo "Text copied to clipboard via pbcopy (macOS)"
            copied=true
        fi
    fi

    if [[ "$copied" == false ]]; then
        echo "Warning: No suitable clipboard tool found. Install wl-clipboard (Wayland) or xclip/xsel (X11)" >&2
        echo "ASCII art saved to $FIGLET_FILE" >&2
        return 1
    fi

    return 0
}

# Save to file with heredoc wrapper
save_to_file() {
    local content="$1"
    local text="$2"

    {
        echo "cat <<\"EOF\""
        echo "$content"
        echo ""
        echo "EOF"
    } > "$FIGLET_FILE" 2>/dev/null || {
        echo "Error: Failed to save to file" >&2
        return 1
    }
}

# List available fonts
list_fonts() {
    if command -v figlet >/dev/null 2>&1; then
        echo "Available figlet fonts:"
        figlet -l 2>/dev/null | head -20 || echo "Run 'figlet -l' to see all fonts"
    else
        echo "Error: figlet not installed" >&2
        return 1
    fi
}

# Usage information
usage() {
    cat << EOF
ASCII Art Generator

Usage: $0 [OPTIONS] [TEXT]

Options:
    -f, --font FONT    Font to use (default: smslant)
    -l, --list         List available fonts
    -h, --help         Show this help message

Arguments:
    TEXT               Text to convert to ASCII art (prompted if not provided)

Environment Variables:
    FIGLET_FONT        Default font to use (default: smslant)
    FIGLET_FILE        Output file path (default: ~/figlet.txt)

Examples:
    $0                          # Interactive mode
    $0 "Hello World"            # Generate ASCII art for "Hello World"
    $0 -f banner "Hello"        # Use banner font
    $0 --list                    # List available fonts

Note: The generated ASCII art is automatically copied to clipboard and saved to ~/figlet.txt
EOF
}

# Main function
main() {
    local text=""
    local font="$FIGLET_FONT"
    local list_fonts_flag=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--font)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: Font name required for -f/--font" >&2
                    exit 1
                fi
                font="$2"
                shift 2
                ;;
            -l|--list)
                list_fonts_flag=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                echo "Error: Unknown option '$1'" >&2
                usage >&2
                exit 1
                ;;
            *)
                text="$1"
                shift
                ;;
        esac
    done

    check_dependencies

    # Handle list fonts
    if [[ "$list_fonts_flag" == true ]]; then
        list_fonts
        exit 0
    fi

    # Get text input if not provided
    if [[ -z "$text" ]]; then
        # Show banner
        generate_ascii_art "Figlet" "$font" 2>/dev/null || true
        echo

        read -p "Enter the text for ASCII encoding: " text

        if [[ -z "$text" ]]; then
            echo "Error: No text provided" >&2
            exit 1
        fi
    fi

    # Generate ASCII art
    local ascii_art
    ascii_art=$(generate_ascii_art "$text" "$font") || exit 1

    # Display generated art
    echo "Generated ASCII art:"
    echo "===================="
    echo "$ascii_art"
    echo

    # Save to file
    save_to_file "$ascii_art" "$text" || true

    # Copy to clipboard
    copy_to_clipboard "$ascii_art" || true
}

main "$@"
