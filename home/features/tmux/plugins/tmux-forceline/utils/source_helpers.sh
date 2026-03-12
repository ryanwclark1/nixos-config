#!/usr/bin/env bash
# Standard module bootstrap for tmux-forceline
# Source this instead of per-module helpers.sh files
#
# Provides: common.sh + platform.sh + thresholds.sh + module_cache.sh

FORCELINE_UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$FORCELINE_UTILS_DIR/common.sh"
source "$FORCELINE_UTILS_DIR/platform.sh"
source "$FORCELINE_UTILS_DIR/thresholds.sh"
source "$FORCELINE_UTILS_DIR/module_cache.sh"

FORCELINE_DIR="$(get_forceline_dir)"
