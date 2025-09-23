# vim:set ft=tmux:
# tmux-forceline Entry Point
# Load configuration files in proper order

# Set global tmux option for forceline root directory
# This provides a centralized path reference for all modules and scripts
set -g @forceline_dir "#{d:current_file}"

# Load options first
source -F "#{d:current_file}/forceline_options_tmux.conf"

# Load main configuration
source -F "#{d:current_file}/forceline_tmux.conf"