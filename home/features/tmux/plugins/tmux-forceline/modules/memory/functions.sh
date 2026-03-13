#!/usr/bin/env bash
# Pure memory functions for tmux-forceline
# Source this file — not meant to be executed directly

# Guard: skip if already loaded via source_helpers.sh (which includes common.sh)
if [[ -z "${FL_VERSION:-}" ]]; then
    source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/pure_helpers.sh"
fi

# macOS specific function for vm_stat parsing
sum_macos_vm_stats() {
    grep -Eo '[0-9]+' |
        awk '{ a += $1 * 4096 } END { print a }'
}

print_memory_percentage() {
    local format="${1:-%3.1f%%}"

    if command_exists "free"; then
        # Linux and other systems with 'free' command
        cached_eval free | awk -v format="$format" '$1 ~ /Mem/ {printf(format, 100*$3/$2)}'
    elif command_exists "vm_stat"; then
        # macOS with vm_stat - page size of 4096 bytes
        local stats used_and_cached cached free used total
        stats="$(cached_eval vm_stat)"

        used_and_cached=$(
            echo "$stats" |
                grep -E "(Pages active|Pages inactive|Pages speculative|Pages wired down|Pages occupied by compressor)" |
                sum_macos_vm_stats
        )

        cached=$(
            echo "$stats" |
                grep -E "(Pages purgeable|File-backed pages)" |
                sum_macos_vm_stats
        )

        free=$(
            echo "$stats" |
                grep -E "(Pages free)" |
                sum_macos_vm_stats
        )

        used=$((used_and_cached - cached))
        total=$((used_and_cached + free))

        echo "$used $total" | awk -v format="$format" '{printf(format, 100*$1/$2)}'
    else
        echo "N/A"
    fi
}
