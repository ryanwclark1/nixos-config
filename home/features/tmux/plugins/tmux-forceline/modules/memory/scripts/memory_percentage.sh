#!/usr/bin/env bash
# Memory percentage script for tmux-forceline v3.0
# Dedicated system memory monitoring with enhanced performance

set -euo pipefail

# Source centralized path management
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
    # shellcheck source=scripts/helpers.sh
    HELPERS_PATH="$(get_forceline_path "modules/memory/scripts/helpers.sh")"
    source "$HELPERS_PATH"
else
    # Fallback implementation if common.sh not available
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CURRENT_DIR/helpers.sh"
fi

# Default memory percentage format
memory_percentage_format="%3.1f%%"

# macOS specific function for vm_stat parsing
sum_macos_vm_stats() {
  grep -Eo '[0-9]+' |
    awk '{ a += $1 * 4096 } END { print a }'
}

# Get memory percentage with platform-specific implementation
print_memory_percentage() {
  local format
  format=$(get_tmux_option "@memory_percentage_format" "$memory_percentage_format")

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
    # Fallback for unsupported systems
    echo "N/A"
  fi
}

# Main function
main() {
  print_memory_percentage
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
