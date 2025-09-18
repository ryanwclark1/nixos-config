# Server tmux-forceline v2.0 Configuration
# Optimized for server monitoring and system administration

# Theme configuration
set -g @forceline_theme "catppuccin-frappe"

# Server-focused plugins
set -g @forceline_plugins "cpu,memory,load,uptime,hostname,disk_usage,wan_ip,lan_ip"

# CPU monitoring with temperature
set -g @forceline_cpu_temp_enabled "yes"
set -g @forceline_cpu_high_threshold "75"
set -g @forceline_cpu_critical_threshold "85"

# Memory monitoring
set -g @forceline_memory_format "percentage"
set -g @forceline_memory_high_threshold "80"
set -g @forceline_memory_critical_threshold "95"

# Load monitoring with color indicators
set -g @forceline_load_format "average"
set -g @forceline_load_precision "2"
set -g @forceline_load_show_color "yes"

# Disk monitoring for root filesystem
set -g @forceline_disk_usage_path "/"
set -g @forceline_disk_usage_format "full"
set -g @forceline_disk_usage_show_path "no"
set -g @forceline_disk_usage_warning_threshold "80"
set -g @forceline_disk_usage_critical_threshold "90"

# Network monitoring
set -g @forceline_wan_ip_cache_ttl "1800"  # 30 minutes
set -g @forceline_wan_ip_show_status "yes"
set -g @forceline_lan_ip_format "primary"
set -g @forceline_lan_ip_show_interface "yes"

# Hostname with full display
set -g @forceline_hostname_format "long"
set -g @forceline_hostname_show_icon "yes"

# Server-optimized status line
set -g status-left "#[fg=#{@fl_base00},bg=#{@fl_primary}] #{hostname} #[fg=#{@fl_primary},bg=#{@fl_surface_0}]#[fg=#{@fl_fg},bg=#{@fl_surface_0}] ↑#{uptime_compact} #[default] "

set -g status-right "#[fg=#{@forceline_load_fg_color},bg=#{@forceline_load_bg_color}] #{load_average} #[default]#[fg=#{@fl_surface_0},bg=default]#[fg=#{@forceline_cpu_fg_color},bg=#{@forceline_cpu_bg_color}] #{cpu_percentage} #[default]#[fg=#{@forceline_memory_fg_color},bg=#{@forceline_memory_bg_color}] #{memory_percentage} #[default]#[fg=#{@forceline_disk_usage_fg_color},bg=#{@forceline_disk_usage_bg_color}] #{disk_usage} #[default]#[fg=#{@fl_surface_0},bg=default]#[fg=#{@fl_fg},bg=#{@fl_surface_0}] #{lan_ip} #[default]"

# Window styling for server environments
set -g @forceline_window_status_style "basic"
set -g @forceline_window_number_position "left"

# Performance settings for server use
set -g @forceline_update_interval "2"
set -g @forceline_cache_enabled "yes"
set -g @forceline_cache_ttl "10"

# Load tmux-forceline
source "~/.config/tmux/plugins/tmux-forceline/forceline_options_tmux.conf"
source "~/.config/tmux/plugins/tmux-forceline/forceline_tmux.conf"