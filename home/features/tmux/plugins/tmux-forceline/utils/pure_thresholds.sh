#!/usr/bin/env bash
# Pure threshold classification for tmux-forceline — NO tmux dependencies
# Usage: classify_level <percentage> <medium_thresh> <high_thresh>
# Usage: classify_temp <temperature> <medium_thresh> <high_thresh>

# Float comparison: returns 0 (true) if n1 <= n2
fcomp() {
    awk -v n1="$1" -v n2="$2" 'BEGIN {if (n1<=n2) exit 0; exit 1}'
}

# Classify a percentage value into low/medium/high
# Takes explicit thresholds — no tmux option reads
classify_level() {
    local percentage="$1"
    local medium_thresh="${2:-30}"
    local high_thresh="${3:-80}"

    if fcomp "$high_thresh" "$percentage"; then
        echo "high"
    elif fcomp "$medium_thresh" "$percentage" && fcomp "$percentage" "$high_thresh"; then
        echo "medium"
    else
        echo "low"
    fi
}

# Classify a temperature value into low/medium/high
classify_temp() {
    local temp="$1"
    local medium_thresh="${2:-80}"
    local high_thresh="${3:-90}"

    if fcomp "$high_thresh" "$temp"; then
        echo "high"
    elif fcomp "$medium_thresh" "$temp" && fcomp "$temp" "$high_thresh"; then
        echo "medium"
    else
        echo "low"
    fi
}

# Backward compatibility aliases
load_status() { classify_level "$@"; }
temp_status() { classify_temp "$@"; }

export -f fcomp classify_level classify_temp load_status temp_status
