#!/usr/bin/env bash
# Standard module bootstrap for tmux-forceline
# Source this instead of per-module helpers.sh files
#
# Provides: common.sh + platform.sh + thresholds.sh + module_cache.sh

export FORCELINE_DIR="${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
FORCELINE_UTILS_DIR="$FORCELINE_DIR/utils"

source "$FORCELINE_UTILS_DIR/common.sh"
source "$FORCELINE_UTILS_DIR/platform.sh"
source "$FORCELINE_UTILS_DIR/thresholds.sh"
source "$FORCELINE_UTILS_DIR/module_cache.sh"
