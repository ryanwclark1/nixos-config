# Developer tmux-forceline v2.0 Configuration
# Full-featured setup for development environments

# Theme configuration
set -g @forceline_theme "catppuccin-frappe"

# Extended plugins (full development stack)
set -g @forceline_plugins "cpu,memory,battery,datetime,hostname,load,uptime,lan_ip,disk_usage,vcs"

# VCS configuration for Git projects
set -g @forceline_vcs_show_icon "yes"
set -g @forceline_vcs_branch_max_len "25"
set -g @forceline_vcs_show_symbols "yes"
set -g @forceline_vcs_format "full"  # Show branch and status

# Network monitoring
set -g @forceline_lan_ip_show_interface "yes"

# Disk monitoring for project directories
set -g @forceline_disk_usage_path "/"
set -g @forceline_disk_usage_format "percentage"
set -g @forceline_disk_usage_warning_threshold "85"

# DateTime with timezone
set -g @forceline_datetime_format "combined"
set -g @forceline_datetime_timezone ""  # Use system timezone

# Advanced status line with colors
set -g status-left "#[fg=#{@fl_base00},bg=#{@fl_primary}] #{hostname} #[fg=#{@fl_primary},bg=#{@fl_surface_0}]#[fg=#{@fl_fg},bg=#{@fl_surface_0}] #{uptime_compact} #[default] "

set -g status-right "#[fg=#{@forceline_load_fg_color},bg=#{@forceline_load_bg_color}] #{load_1min} #[default]#[fg=#{@fl_surface_0},bg=default]#[fg=#{@fl_fg},bg=#{@fl_surface_0}] #{disk_usage} #[default]#[fg=#{@forceline_vcs_fg_color},bg=#{@forceline_vcs_bg_color}] #{vcs_branch} #{vcs_status_counts} #[default]#[fg=#{@fl_surface_0},bg=default]#[fg=#{@fl_fg},bg=#{@fl_surface_0}] #{datetime_time} #[default]"

# Window styling for development
set -g @forceline_window_status_style "slanted"
set -g @forceline_window_flags "icon"
set -g @forceline_window_number_position "left"

# Performance optimized for development
set -g @forceline_update_interval "1"
set -g @forceline_cache_enabled "yes"
set -g @forceline_cache_ttl "3"

# Load tmux-forceline
source "~/.config/tmux/plugins/tmux-forceline/forceline_options_tmux.conf"
source "~/.config/tmux/plugins/tmux-forceline/forceline_tmux.conf"