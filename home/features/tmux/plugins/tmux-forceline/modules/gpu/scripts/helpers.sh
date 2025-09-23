#!/usr/bin/env bash
# Helper functions for GPU module
# Shared utilities for GPU monitoring, temperature tracking, and performance analysis

export LANG=C
export LC_ALL=C

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
    
    get_forceline_dir() {
        echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    }
fi

is_osx() {
  [ "$(uname)" == "Darwin" ]
}

is_freebsd() {
  [ "$(uname)" == "FreeBSD" ]
}

is_openbsd() {
  [ "$(uname)" == "OpenBSD" ]
}

is_linux() {
  [ "$(uname)" == "Linux" ]
}

is_cygwin() {
  command -v WMIC &>/dev/null
}

is_linux_iostat() {
  # Bug in early versions of linux iostat -V return error code
  iostat -c &>/dev/null
}

# is second float bigger or equal?
fcomp() {
  awk -v n1="$1" -v n2="$2" 'BEGIN {if (n1<=n2) exit 0; exit 1}'
}

load_status() {
  local percentage=$1
  local prefix=$2
  medium_thresh=$(get_tmux_option "@${prefix}_medium_thresh" "30")
  high_thresh=$(get_tmux_option "@${prefix}_high_thresh" "80")
  if fcomp "$high_thresh" "$percentage"; then
    echo "high"
  elif fcomp "$medium_thresh" "$percentage" && fcomp "$percentage" "$high_thresh"; then
    echo "medium"
  else
    echo "low"
  fi
}

temp_status() {
  local temp
  temp=$1
  cpu_temp_medium_thresh=$(get_tmux_option "@cpu_temp_medium_thresh" "80")
  cpu_temp_high_thresh=$(get_tmux_option "@cpu_temp_high_thresh" "90")
  if fcomp "$cpu_temp_high_thresh" "$temp"; then
    echo "high"
  elif fcomp "$cpu_temp_medium_thresh" "$temp" && fcomp "$temp" "$cpu_temp_high_thresh"; then
    echo "medium"
  else
    echo "low"
  fi
}

cpus_number() {
  if is_linux; then
    if command_exists "nproc"; then
      nproc
    else
      echo "$(($(sed -n 's/^processor.*:\s*\([0-9]\+\)/\1/p' /proc/cpuinfo | tail -n 1) + 1))"
    fi
  else
    sysctl -n hw.ncpu
  fi
}

command_exists() {
  local command
  command="$1"
  command -v "$command" &>/dev/null
}

# Get cache directory for GPU module
get_cache_dir() {
  local cache_dir="${TMUX_TMPDIR:-${TMPDIR:-/tmp}}/tmux-forceline-gpu"
  mkdir -p "$cache_dir" 2>/dev/null || {
    echo "/tmp" # Fallback
    return 1
  }
  echo "$cache_dir"
}

# Check if cached result is still valid
is_cache_valid() {
  local cache_file="$1"
  local max_age="$2"
  
  [[ -f "$cache_file" ]] || return 1
  
  local file_age
  if command -v stat >/dev/null 2>&1; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      file_age=$(stat -f %m "$cache_file" 2>/dev/null || echo 0)
    else
      file_age=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
    fi
  else
    return 1
  fi
  
  local current_time
  current_time=$(date +%s)
  
  [ $((current_time - file_age)) -lt "$max_age" ]
}

# Cache command output with TTL optimized for GPU monitoring
cached_eval() {
  local cache_dir cache_file command_hash
  cache_dir=$(get_cache_dir) || {
    eval "$*"
    return
  }
  
  # Create hash of command for cache filename
  command_hash=$(echo "$*" | cksum | cut -d' ' -f1)
  cache_file="$cache_dir/cmd_${command_hash}.cache"
  
  # Return cached result if valid (1 second TTL for GPU - same as CPU for responsive monitoring)
  if is_cache_valid "$cache_file" 1; then
    cat "$cache_file" 2>/dev/null && return 0
  fi
  
  # Execute and cache result
  eval "$*" | tee "$cache_file" 2>/dev/null || eval "$*"
}
