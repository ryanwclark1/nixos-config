#!/usr/bin/env bash
# Platform detection utilities for tmux-forceline
# Extracted from per-module helpers.sh files to eliminate duplication

export LANG=C
export LC_ALL=C

is_osx() {
  [ "$(uname)" = "Darwin" ]
}

is_linux() {
  [ "$(uname)" = "Linux" ]
}

is_freebsd() {
  [ "$(uname)" = "FreeBSD" ]
}

is_openbsd() {
  [ "$(uname)" = "OpenBSD" ]
}

is_cygwin() {
  command -v WMIC &>/dev/null
}

is_wsl() {
  [ -f /proc/version ] && grep -qi microsoft /proc/version 2>/dev/null
}

is_chrome() {
  uname -a | grep -qi "chrome" 2>/dev/null
}

is_linux_iostat() {
  iostat -c &>/dev/null
}

# Cross-platform CPU count
get_nproc() {
  if command -v nproc >/dev/null 2>&1; then
    nproc
  elif is_linux && [ -f /proc/cpuinfo ]; then
    echo "$(($(sed -n 's/^processor.*:\s*\([0-9]\+\)/\1/p' /proc/cpuinfo | tail -n 1) + 1))"
  else
    sysctl -n hw.ncpu 2>/dev/null || echo 1
  fi
}

# Export all platform functions
export -f is_osx is_linux is_freebsd is_openbsd is_cygwin is_wsl is_chrome is_linux_iostat get_nproc
