#!/usr/bin/env bash
# Helper functions for memory module
# Shared utilities for system memory monitoring

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

# Platform detection functions
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

# Check if command exists
command_exists() {
  local command="$1"
  command -v "$command" >/dev/null 2>&1
}

# Get cache directory
get_cache_dir() {
  local cache_dir="${TMUX_TMPDIR:-${TMPDIR:-/tmp}}/tmux-forceline-memory"
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

# Cache command output with TTL
cached_eval() {
  local cache_dir cache_file command_hash
  cache_dir=$(get_cache_dir) || {
    eval "$*"
    return
  }
  
  # Create hash of command for cache filename
  command_hash=$(echo "$*" | cksum | cut -d' ' -f1)
  cache_file="$cache_dir/cmd_${command_hash}.cache"
  
  # Return cached result if valid (5 second TTL for memory)
  if is_cache_valid "$cache_file" 5; then
    cat "$cache_file" 2>/dev/null && return 0
  fi
  
  # Execute and cache result
  eval "$*" | tee "$cache_file" 2>/dev/null || eval "$*"
}