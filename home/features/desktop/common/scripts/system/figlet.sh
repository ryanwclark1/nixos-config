#!/usr/bin/env bash

# Check if figlet is available
if ! command -v figlet >/dev/null 2>&1; then
    echo "Error: figlet is not installed. Please install figlet first."
    echo "On NixOS: add 'figlet' to your packages"
    exit 1
fi

figlet -f smslant "Figlet"
echo
# ------------------------------------------------
# Script to create ascii font based header on user input
# and copy the result to the clipboard
# -----------------------------------------------------

read -p "Enter the text for ascii encoding: " mytext

# Validate input
if [[ -z "$mytext" ]]; then
    echo "Error: No text provided"
    exit 1
fi

# Create/recreate the figlet file
figlet_file="$HOME/figlet.txt"

# Generate the figlet output with heredoc wrapper
if ! {
    echo "cat <<\"EOF\""
    figlet -f smslant "$mytext"
    echo ""
    echo "EOF"
} > "$figlet_file" 2>/dev/null; then
    echo "Error: Failed to generate figlet output"
    exit 1
fi

# Read the generated content
if ! lines=$(cat "$figlet_file" 2>/dev/null); then
    echo "Error: Failed to read generated figlet file"
    exit 1
fi

echo "Generated ASCII art:"
echo "===================="
figlet -f smslant "$mytext"
echo

# Smart clipboard handling with fallbacks
copy_to_clipboard() {
    local content="$1"
    local copied=false
    
    # Try Wayland clipboard first (wl-copy)
    if command -v wl-copy >/dev/null 2>&1; then
        if wl-copy "$content" 2>/dev/null; then
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
        echo "Warning: No suitable clipboard tool found. Install wl-clipboard (Wayland) or xclip/xsel (X11)"
        echo "ASCII art saved to ~/figlet.txt"
        return 1
    fi
    
    return 0
}

# Copy to clipboard
copy_to_clipboard "$lines"
