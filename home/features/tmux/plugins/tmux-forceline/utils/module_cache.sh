#!/usr/bin/env bash
# Caching utilities for tmux-forceline modules
# Extracted from per-module helpers.sh files to eliminate duplication

# Get cache directory for a module
# Usage: get_module_cache_dir <module_name>
get_module_cache_dir() {
  local module="${1:-generic}"
  local cache_dir="${TMPDIR:-/tmp}/tmux-forceline-${module}"
  mkdir -p "$cache_dir" 2>/dev/null || {
    echo "/tmp"
    return 1
  }
  echo "$cache_dir"
}

# Check if cached result is still valid
# Usage: is_cache_valid <cache_file> <max_age_seconds>
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

# Cache command output with configurable TTL
# Usage: cached_eval <ttl_seconds> <module_name> <command...>
# For backward compat: cached_eval <command...> (uses 1s TTL and "generic" module)
cached_eval() {
  local ttl module cache_dir cache_file command_hash

  # Detect new vs. legacy calling convention
  if [[ "$1" =~ ^[0-9]+$ ]] && [[ $# -ge 3 ]]; then
    ttl="$1"; shift
    module="$1"; shift
  else
    ttl=1
    module="generic"
  fi

  cache_dir=$(get_module_cache_dir "$module") || {
    "$@"
    return
  }

  command_hash=$(echo "$@" | cksum | cut -d' ' -f1)
  cache_file="$cache_dir/cmd_${command_hash}.cache"

  if is_cache_valid "$cache_file" "$ttl"; then
    cat "$cache_file" 2>/dev/null && return 0
  fi

  local tmp="${cache_file}.$$"
  "$@" | tee "$tmp" 2>/dev/null && mv "$tmp" "$cache_file" || "$@"
}

export -f get_module_cache_dir is_cache_valid cached_eval
