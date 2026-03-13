#!/usr/bin/env bash
# Pure GPU functions for tmux-forceline
# Source this file — not meant to be executed directly

# Guard: skip if already loaded via source_helpers.sh (which includes common.sh)
if [[ -z "${FL_VERSION:-}" ]]; then
    source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/pure_helpers.sh"
fi

find_amd_gpu() {
    # Prefer the discrete GPU (higher card number typically)
    for card in /sys/class/drm/card*/device/gpu_busy_percent; do
        [ -f "$card" ] && echo "$card"
    done | tail -1
}

print_gpu_percentage() {
    local gpu_percentage_format="${1:-%3.1f%%}"

    if command_exists "nvidia-smi"; then
        loads=$(cached_eval nvidia-smi)
        echo "$loads" | sed -nr 's/.*\s([0-9]+)%.*/\1/p' | awk -v fmt="$gpu_percentage_format" '{sum+=$1; n+=1} END {printf fmt, sum/n}'
    else
        local gpu_sysfs
        gpu_sysfs=$(find_amd_gpu)
        if [ -n "$gpu_sysfs" ]; then
            pct=$(cat "$gpu_sysfs" 2>/dev/null || echo "0")
            printf "$gpu_percentage_format" "$pct"
        elif command_exists "radeontop"; then
            pct=$(radeontop -d - -l 1 2>/dev/null | grep -oP 'gpu \K[0-9.]+' | head -1)
            printf "$gpu_percentage_format" "${pct:-0}"
        else
            echo "N/A"
        fi
    fi
}

print_gpu_temp() {
    local gpu_temp_format="${1:-%2.0f}"
    local gpu_temp_unit="${2:-C}"

    if command_exists "nvidia-smi"; then
        loads=$(cached_eval nvidia-smi)
    elif command_exists "cuda-smi"; then
        loads=$(cached_eval cuda-smi)
    else
        echo "No GPU"
        return
    fi
    tempC=$(echo "$loads" | sed -nr 's/.*\s([0-9]+)C.*/\1/p' | awk '{sum+=$1; n+=1} END {printf "%5.3f", sum/n}')
    if [ "$gpu_temp_unit" == "C" ]; then
        echo "$tempC" | awk -v format="${gpu_temp_format}C" '{sum+=$1} END {printf format, sum}'
    else
        echo "$tempC" | awk -v format="${gpu_temp_format}F" '{sum+=$1} END {printf format, sum*9/5+32}'
    fi
}
