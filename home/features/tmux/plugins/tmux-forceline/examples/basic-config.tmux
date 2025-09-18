# Basic tmux-forceline v2.0 Configuration
# Simple setup with core modules only

# Theme configuration
set -g @forceline_theme "catppuccin-frappe"

# Core plugins (essential system monitoring)
set -g @forceline_plugins "cpu,memory,battery,datetime"

# Basic status line configuration
set -g status-position bottom
set -g status-left "#[fg=#{@fl_base00},bg=#{@fl_primary}] #{hostname_short} #[default] "
set -g status-right "#{cpu_percentage} | #{memory_percentage} | #{battery_percentage} | #{datetime_time}"

# Window status styling
set -g @forceline_window_status_style "basic"
set -g @forceline_window_number_position "left"

# Performance settings
set -g @forceline_update_interval "2"
set -g @forceline_cache_enabled "yes"

# Load tmux-forceline
source "~/.config/tmux/plugins/tmux-forceline/forceline_options_tmux.conf"
source "~/.config/tmux/plugins/tmux-forceline/forceline_tmux.conf"