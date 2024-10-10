#!/usr/bin/env bash

set -o errexit
set -o pipefail

# Set path of script
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tmux source "${PLUGIN_DIR}/forceline_options_tmux.conf"
tmux source "${PLUGIN_DIR}/forceline_tmux.conf"
