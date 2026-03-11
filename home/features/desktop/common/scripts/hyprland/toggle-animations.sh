#!/usr/bin/env bash

set -euo pipefail

# Configuration
CACHE_FILE="$HOME/.cache/toggle_animation"
ANIMATION_CONF="$HOME/.config/hypr/conf/animation.conf"

# Check required commands
if ! command -v hyprctl >/dev/null 2>&1; then
    echo "Error: hyprctl not found" >&2
    exit 1
fi

# Check if animations are disabled in config
if [[ -f "$ANIMATION_CONF" ]]; then
    if grep -q "disabled" "$ANIMATION_CONF" 2>/dev/null; then
        echo ":: Toggle blocked by disabled.conf variation."
        exit 0
    fi
fi

# Ensure cache directory exists
mkdir -p "$(dirname "$CACHE_FILE")"

# Toggle animations
if [[ -f "$CACHE_FILE" ]]; then
    # Enable animations
    if hyprctl keyword animations:enabled true >/dev/null 2>&1; then
        rm -f "$CACHE_FILE"
        echo ":: Animations enabled"
    else
        echo "Error: Failed to enable animations" >&2
        exit 1
    fi
else
    # Disable animations
    if hyprctl keyword animations:enabled false >/dev/null 2>&1; then
        touch "$CACHE_FILE"
        echo ":: Animations disabled"
    else
        echo "Error: Failed to disable animations" >&2
        exit 1
    fi
fi
