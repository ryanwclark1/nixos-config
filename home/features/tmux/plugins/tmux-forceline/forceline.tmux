#!/usr/bin/env bash

set -o errexit
set -o pipefail

# Set path of script
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tmux source "${PLUGIN_DIR}/forceline_options_tmux.conf"
tmux source "${PLUGIN_DIR}/forceline_tmux.conf"
tmux run-shell "${PLUGIN_DIR}/modules/weather/weather.sh"
tmux run-shell "${PLUGIN_DIR}/modules/cpu/cpu.tmux"
tmux run-shell "${PLUGIN_DIR}/modules/ipwan/ipwan.tmux"