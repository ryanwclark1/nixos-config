#!/usr/bin/env bash
# Hardware-aware configuration generator for tmux-forceline
# Generates conditional plugin loading based on actual hardware detection

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities if available
if [[ -f "$SCRIPT_DIR/common.sh" ]]; then
    # shellcheck source=common.sh
    source "$SCRIPT_DIR/common.sh"
else
    log_info() { echo "[INFO] $*" >&2; }
    log_error() { echo "[ERROR] $*" >&2; }
fi

# Use centralized path management
FORCELINE_DIR="$(get_forceline_dir)"
PLUGIN_DIR="$FORCELINE_DIR/plugins"
OUTPUT_FILE="$PLUGIN_DIR/hardware_aware_loader.conf"

# Run hardware detection using centralized path
if [[ -f "$FORCELINE_DIR/utils/hardware_detection.sh" ]]; then
    hardware_info=$("$FORCELINE_DIR/utils/hardware_detection.sh" detect)
    
    # Parse hardware information
    eval "$hardware_info"
    
    log_info "Generating hardware-aware config: laptop=$IS_LAPTOP, os=$OS_TYPE"
else
    log_error "Hardware detection script not found, using defaults"
    IS_LAPTOP="false"
    OS_TYPE="linux"
    CAPABILITIES="cpu,memory,load,uptime,hostname,datetime"
fi

# Generate the hardware-aware plugin loader
cat > "$OUTPUT_FILE" << 'EOF'
# vim:set ft=tmux:
# Hardware-Aware Plugin Loader (Generated)
# This file is auto-generated based on hardware detection

# Plugin system configuration
set -ogq @forceline_plugin_auto_load "yes"
set -ogq @forceline_plugin_path "#{@forceline_dir}/plugins"
set -ogq @forceline_user_plugin_path "~/.config/tmux/forceline/plugins"

# Plugin loading state
set -g @_fl_plugins_loaded ""
set -g @_fl_plugins_failed ""
set -g @_fl_hardware_detected "yes"

EOF

# Add hardware detection results as static values
cat >> "$OUTPUT_FILE" << EOF
# Hardware detection results (static)
set -g @_fl_is_laptop "$IS_LAPTOP"
set -g @_fl_os_type "$OS_TYPE"
set -g @_fl_capabilities "$CAPABILITIES"

EOF

# Add core plugins (always loaded)
cat >> "$OUTPUT_FILE" << 'EOF'
# Core plugins (always loaded)
set -g @_fl_core_plugins "hostname,datetime,cpu,memory,load,uptime"

# Load essential plugins using centralized path
source -qF "#{@forceline_dir}/plugins/core/hostname/hostname.conf"
source -qF "#{@forceline_dir}/plugins/core/datetime/datetime.conf"
source -qF "#{@forceline_dir}/plugins/core/cpu/cpu.conf"
source -qF "#{@forceline_dir}/plugins/core/memory/memory.conf"
source -qF "#{@forceline_dir}/plugins/core/load/load.conf"
source -qF "#{@forceline_dir}/plugins/core/uptime/uptime.conf"

EOF

# Conditional battery loading based on hardware detection
if [[ "$IS_LAPTOP" == "true" ]]; then
    cat >> "$OUTPUT_FILE" << 'EOF'
# Load battery plugin (laptop detected)
source -qF "#{@forceline_dir}/plugins/core/battery/battery.conf"
set -ag @_fl_loaded_plugins "battery,"

EOF
    log_info "Including battery module for laptop"
else
    cat >> "$OUTPUT_FILE" << 'EOF'
# Battery plugin skipped (desktop detected)
set -g @_fl_battery_skipped "yes"

EOF
    log_info "Skipping battery module for desktop"
fi

# Add development and system plugins
cat >> "$OUTPUT_FILE" << 'EOF'
# Load development plugins
source -qF "#{@forceline_dir}/plugins/extended/vcs/vcs.conf"
source -qF "#{@forceline_dir}/plugins/core/directory/directory.conf"

# Load system plugins
source -qF "#{@forceline_dir}/plugins/extended/disk_usage/disk_usage.conf"
source -qF "#{@forceline_dir}/plugins/core/session/session.conf"

# Load network plugins
source -qF "#{@forceline_dir}/plugins/extended/lan_ip/lan_ip.conf"
source -qF "#{@forceline_dir}/plugins/extended/wan_ip/wan_ip.conf"

# Load enhanced plugins
source -qF "#{@forceline_dir}/plugins/extended/weather/weather.conf"
source -qF "#{@forceline_dir}/plugins/extended/now_playing/now_playing.conf"
source -qF "#{@forceline_dir}/plugins/extended/network/network.conf"

# Build plugin list
set -g @_fl_all_plugins "#{@_fl_core_plugins},vcs,directory,disk_usage,session,lan_ip,wan_ip,weather,now_playing,network"

EOF

# Add battery to plugin list if it's a laptop
if [[ "$IS_LAPTOP" == "true" ]]; then
    cat >> "$OUTPUT_FILE" << 'EOF'
set -ag @_fl_all_plugins ",battery"

EOF
fi

# Finish the configuration
cat >> "$OUTPUT_FILE" << 'EOF'
# Display loading summary
%if "#{==:#{@forceline_debug_modules},yes}"
  display-message "Hardware-aware loading: laptop=#{@_fl_is_laptop}, plugins=#{@_fl_all_plugins}"
%endif

# Register loaded plugins for status bar configuration
set -g @forceline_active_plugins "#{@_fl_all_plugins}"
EOF

log_info "Generated hardware-aware config: $OUTPUT_FILE"