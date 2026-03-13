#!/usr/bin/env bash
# Pure graphics memory functions for tmux-forceline
# Source this file — not meant to be executed directly

# Guard: skip if already loaded via source_helpers.sh (which includes common.sh)
if [[ -z "${FL_VERSION:-}" ]]; then
    source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/pure_helpers.sh"
fi

# Inline GPU vendor detection helpers (not provided by platform.sh)
is_nvidia_gpu() { command -v nvidia-smi >/dev/null 2>&1; }
is_amd_gpu() { command -v rocm-smi >/dev/null 2>&1 || { [ -d /sys/class/drm/card0/device ] && grep -qi amd /sys/class/drm/card0/device/vendor 2>/dev/null; }; }
is_intel_gpu() { [ -d /sys/class/drm/card0/device ] && grep -qi intel /sys/class/drm/card0/device/vendor 2>/dev/null; }

# NVIDIA GPU memory via nvidia-smi
nvidia_memory_percentage() {
    if ! command_exists "nvidia-smi"; then
        echo "N/A"
        return 1
    fi

    local memory_info
    memory_info=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null) || {
        echo "N/A"
        return 1
    }

    # Handle multiple GPUs by taking the first one
    memory_info=$(echo "$memory_info" | head -n1)

    local used total
    used=$(echo "$memory_info" | cut -d',' -f1 | tr -d ' ')
    total=$(echo "$memory_info" | cut -d',' -f2 | tr -d ' ')

    if [[ -n "$used" && -n "$total" && "$total" -gt 0 ]]; then
        echo "$((used * 100 / total))%"
    else
        echo "N/A"
    fi
}

# AMD GPU memory via rocm-smi (if available)
amd_memory_percentage() {
    if ! command_exists "rocm-smi"; then
        echo "N/A"
        return 1
    fi

    local memory_info
    memory_info=$(rocm-smi --showmeminfo vram --csv 2>/dev/null | tail -n +2) || {
        echo "N/A"
        return 1
    }

    # Parse CSV output: device,vram_total,vram_used
    local total used
    total=$(echo "$memory_info" | head -n1 | cut -d',' -f2 | tr -d ' ')
    used=$(echo "$memory_info" | head -n1 | cut -d',' -f3 | tr -d ' ')

    if [[ -n "$used" && -n "$total" && "$total" -gt 0 ]]; then
        # Convert bytes to MB to prevent integer overflow
        local used_mb=$((used / 1048576))
        local total_mb=$((total / 1048576))
        if [[ "$total_mb" -gt 0 ]]; then
            echo "$((used_mb * 100 / total_mb))%"
        else
            echo "N/A"
        fi
    else
        echo "N/A"
    fi
}

# Intel GPU memory (integrated graphics) - fallback estimation
intel_memory_percentage() {
    if is_linux && [ -f /proc/meminfo ]; then
        local available_kb total_kb
        available_kb=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo 2>/dev/null)
        total_kb=$(awk '/MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null)

        if [[ -n "$available_kb" && -n "$total_kb" && "$total_kb" -gt 0 ]]; then
            local used_kb=$((total_kb - available_kb))
            local memory_usage_pct=$((used_kb * 100 / total_kb))

            local graphics_estimate
            if [[ "$memory_usage_pct" -lt 30 ]]; then
                graphics_estimate=5
            elif [[ "$memory_usage_pct" -lt 60 ]]; then
                graphics_estimate=10
            else
                graphics_estimate=15
            fi

            echo "${graphics_estimate}%"
        else
            echo "N/A"
        fi
    else
        echo "N/A"
    fi
}

# macOS Metal GPU memory estimation
macos_metal_memory_percentage() {
    if ! is_osx; then
        echo "N/A"
        return 1
    fi

    local vm_stats
    vm_stats=$(vm_stat 2>/dev/null) || {
        echo "N/A"
        return 1
    }

    local pages_free pages_active pages_wired
    pages_free=$(echo "$vm_stats" | awk '/Pages free:/ {print $3}' | tr -d '.')
    pages_active=$(echo "$vm_stats" | awk '/Pages active:/ {print $3}' | tr -d '.')
    pages_wired=$(echo "$vm_stats" | awk '/Pages wired down:/ {print $4}' | tr -d '.')

    if [[ -n "$pages_free" && -n "$pages_active" && -n "$pages_wired" ]]; then
        local total_pages=$((pages_free + pages_active + pages_wired))
        local graphics_pressure=$((pages_wired * 100 / total_pages))

        graphics_pressure=$((graphics_pressure / 2))
        [[ "$graphics_pressure" -gt 100 ]] && graphics_pressure=100

        echo "${graphics_pressure}%"
    else
        echo "N/A"
    fi
}

# Get graphics memory percentage (tries vendors in priority order)
print_graphics_memory_percentage() {
    local percentage="N/A"

    if is_nvidia_gpu; then
        percentage=$(nvidia_memory_percentage)
    fi

    if [[ "$percentage" == "N/A" ]] && is_amd_gpu; then
        percentage=$(amd_memory_percentage)
    fi

    if [[ "$percentage" == "N/A" ]] && is_osx; then
        percentage=$(macos_metal_memory_percentage)
    fi

    if [[ "$percentage" == "N/A" ]] && is_intel_gpu; then
        percentage=$(intel_memory_percentage)
    fi

    echo "$percentage"
}
