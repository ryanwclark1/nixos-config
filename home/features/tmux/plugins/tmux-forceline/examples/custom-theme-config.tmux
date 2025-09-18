# Example Custom Theme Configuration for tmux-forceline
# Demonstrates various ways to configure custom themes

# Example 1: Using a custom YAML theme file
set -g @forceline_theme "custom"
set -g @forceline_custom_theme_path "~/.config/tmux/themes/my-theme.yaml"

# Example 2: Using predefined YAML themes
# set -g @forceline_theme "catppuccin-frappe"  # Default
# set -g @forceline_theme "catppuccin-mocha"
# set -g @forceline_theme "dracula"
# set -g @forceline_theme "nord"
# set -g @forceline_theme "gruvbox-dark"

# Core plugins configuration
set -g @forceline_plugins "cpu,memory,battery,datetime,hostname"

# Advanced configuration with custom theme
set -g status-left "#[fg=#{@fl_base00},bg=#{@fl_primary}] #{hostname} #[fg=#{@fl_primary},bg=#{@fl_surface_0}]#[fg=#{@fl_fg},bg=#{@fl_surface_0}] #{uptime_compact} #[default] "

set -g status-right "#[fg=#{@forceline_cpu_fg_color},bg=#{@forceline_cpu_bg_color}] #{cpu_percentage} #[default]#[fg=#{@fl_surface_0},bg=default]#[fg=#{@forceline_memory_fg_color},bg=#{@forceline_memory_bg_color}] #{memory_percentage} #[default]#[fg=#{@fl_surface_0},bg=default]#[fg=#{@fl_fg},bg=#{@fl_surface_0}] #{datetime_time} #[default]"

# Load tmux-forceline
source "~/.config/tmux/plugins/tmux-forceline/forceline_options_tmux.conf"
source "~/.config/tmux/plugins/tmux-forceline/forceline_tmux.conf"