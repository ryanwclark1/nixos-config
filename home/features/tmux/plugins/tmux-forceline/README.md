# tmux-forceline v3.0

A comprehensive, modular tmux status line system with Base24 theming and extensive plugin ecosystem.

## Overview

tmux-forceline v3.0 is a complete rewrite featuring:

- **Base24 Theme System**: Standardized 24-color palette with semantic aliases
- **Modular Plugin Architecture**: Core and extended modules with dynamic loading
- **Cross-Platform Support**: Linux, macOS, BSD, and WSL compatibility
- **Intelligent Caching**: Smart caching for network requests and expensive operations
- **Dynamic Colors**: Status-based color changes using Base24 semantic colors

## Architecture

### Theme System
- **Base24 Colors**: 24 standardized colors (base00-base17) plus semantic aliases
- **Theme Loader**: Validates and loads themes with fallback support
- **Semantic Aliases**: `@fl_primary`, `@fl_success`, `@fl_error`, `@fl_warning`, etc.

### Plugin System
- **Core Plugins**: Essential modules always available
- **Extended Plugins**: Optional modules loaded on-demand
- **Plugin Loader**: Dynamic discovery and loading with failure tracking
- **Universal Renderer**: Consistent display formatting across all modules

## Installation

1. **Clone Repository**:
   ```bash
   git clone <repository-url> ~/.config/tmux/plugins/tmux-forceline
   ```

2. **Install yq (required for YAML themes)**:
   ```bash
   # macOS with Homebrew
   brew install yq
   
   # Linux with snap
   sudo snap install yq
   
   # Or download binary from https://github.com/mikefarah/yq#install
   ```

3. **Add to tmux.conf**:
   ```tmux
   source ~/.config/tmux/plugins/tmux-forceline/forceline_options_tmux.conf
   source ~/.config/tmux/plugins/tmux-forceline/forceline_tmux.conf
   ```

4. **Reload tmux**:
   ```bash
   tmux source-file ~/.tmux.conf
   ```

**Note**: tmux-forceline v2.0 requires `yq` for YAML theme processing. Legacy theme support has been removed for cleaner architecture.

## Configuration

### Basic Configuration

```tmux
# Theme selection
set -g @forceline_theme "catppuccin-frappe"

# Core plugins (always available)
set -g @forceline_plugins "cpu,memory,battery,datetime,hostname,load,uptime"

# Add extended plugins (optional)
set -g @forceline_plugins "cpu,memory,battery,datetime,hostname,load,uptime,wan_ip,lan_ip,disk_usage,vcs"
```

### Theme Configuration

tmux-forceline v2.0 uses a modern YAML-based theme system built on the Base24 color specification.

#### Predefined YAML Themes

```tmux
# Available YAML themes
set -g @forceline_theme "catppuccin-frappe"  # Default
set -g @forceline_theme "catppuccin-mocha"
set -g @forceline_theme "dracula"
set -g @forceline_theme "nord"
set -g @forceline_theme "gruvbox-dark"
```

#### Custom YAML Themes

```tmux
# Using custom YAML theme
set -g @forceline_theme "custom"
set -g @forceline_custom_theme_path "~/.config/tmux/themes/my-theme.yaml"
```

#### Creating Custom YAML Themes

Create a YAML file following the Base24 specification:

```yaml
system: "base24"
name: "My Theme"
author: "Your Name"
variant: "dark"
palette:
  base00: "#1a1a1a" # background
  base01: "#2a2a2a" # mantle
  # ... (see examples/custom-theme-yaml.yaml for full template)
  base17: "#ea80fc" # bright purple
```

## Core Modules

### CPU Module
**Variables**: `#{cpu_percentage}`, `#{cpu_temp}`, `#{cpu_color_fg}`, `#{cpu_color_bg}`

```tmux
set -g @forceline_cpu_temp_enabled "yes"
set -g @forceline_cpu_high_threshold "80"
set -g @forceline_cpu_critical_threshold "90"
```

### Memory Module
**Variables**: `#{ram_percentage}`, `#{ram_usage}`, `#{ram_total}`

```tmux
set -g @forceline_memory_format "percentage"  # percentage, absolute, both
set -g @forceline_memory_high_threshold "80"
```

### Battery Module
**Variables**: `#{battery_percentage}`, `#{battery_icon}`, `#{battery_status}`

```tmux
set -g @forceline_battery_show_percentage "yes"
set -g @forceline_battery_low_threshold "20"
set -g @forceline_battery_critical_threshold "10"
```

### DateTime Module
**Variables**: `#{datetime_date}`, `#{datetime_time}`, `#{datetime_day_of_week}`, `#{datetime_utc_time}`

```tmux
set -g @forceline_datetime_format "combined"  # date, time, combined, custom
set -g @forceline_datetime_date_format "%Y-%m-%d"
set -g @forceline_datetime_time_format "%H:%M"
set -g @forceline_datetime_timezone "America/Los_Angeles"
```

### Hostname Module
**Variables**: `#{hostname}`, `#{hostname_short}`, `#{hostname_long}`, `#{hostname_icon}`

```tmux
set -g @forceline_hostname_format "short"  # short, long, custom, upper, lower
set -g @forceline_hostname_show_icon "yes"
set -g @forceline_hostname_custom "my-server"
```

### Load Module
**Variables**: `#{load_average}`, `#{load_1min}`, `#{load_5min}`, `#{load_15min}`, `#{load_color_fg}`, `#{load_color_bg}`

```tmux
set -g @forceline_load_format "average"  # average, 1min, 5min, 15min, compact
set -g @forceline_load_precision "1"
set -g @forceline_load_show_color "yes"
```

### Uptime Module
**Variables**: `#{uptime}`, `#{uptime_short}`, `#{uptime_compact}`, `#{uptime_days}`, `#{uptime_hours}`

```tmux
set -g @forceline_uptime_format "short"  # short, compact, days, hours
```

## Extended Modules

### WAN IP Module
**Variables**: `#{wan_ip}`, `#{wan_ip_status}`, `#{wan_ip_color_fg}`, `#{wan_ip_color_bg}`

```tmux
set -g @forceline_wan_ip_cache_ttl "900"  # 15 minutes
set -g @forceline_wan_ip_timeout "3"
set -g @forceline_wan_ip_providers "ipify,icanhazip,checkip"
set -g @forceline_wan_ip_show_status "no"  # Show FRESH/CACHED/STALE status
```

### LAN IP Module
**Variables**: `#{lan_ip}`, `#{lan_ip_primary}`, `#{lan_ip_all}`

```tmux
set -g @forceline_lan_ip_format "primary"  # primary, all
set -g @forceline_lan_ip_interface "eth0"  # Specific interface (empty for auto-detect)
set -g @forceline_lan_ip_show_interface "no"
```

### Disk Usage Module
**Variables**: `#{disk_usage}`, `#{disk_usage_status}`, `#{disk_usage_percentage}`, `#{disk_usage_used}`, `#{disk_usage_available}`

```tmux
set -g @forceline_disk_usage_path "/"  # Path to monitor
set -g @forceline_disk_usage_format "percentage"  # percentage, used, available, size, compact, full
set -g @forceline_disk_usage_warning_threshold "80"
set -g @forceline_disk_usage_critical_threshold "90"
```

### VCS Module
**Variables**: `#{vcs_branch}`, `#{vcs_status}`, `#{vcs_status_counts}`, `#{vcs_type}`, `#{vcs_color_fg}`, `#{vcs_color_bg}`

```tmux
set -g @forceline_vcs_show_icon "yes"
set -g @forceline_vcs_branch_max_len "20"
set -g @forceline_vcs_truncate_symbol "…"
set -g @forceline_vcs_show_symbols "yes"  # Use ±, +, ? symbols
set -g @forceline_vcs_format "branch"  # branch, status, full
```

## Status Line Configuration

### Basic Status Line
```tmux
set -g status-right "#{cpu_percentage} | #{memory_percentage} | #{battery_percentage} | #{datetime_time}"
```

### Advanced Status Line with Colors
```tmux
set -g status-right "#[fg=#{@forceline_cpu_fg_color},bg=#{@forceline_cpu_bg_color}] #{cpu_percentage} #[default] | #[fg=#{@forceline_vcs_fg_color},bg=#{@forceline_vcs_bg_color}] #{vcs_branch} #{vcs_status_counts} #[default]"
```

### Complete Status Line Example
```tmux
set -g status-left "#[fg=#{@fl_base00},bg=#{@fl_primary}] #{hostname} #[default] "
set -g status-right "#[fg=#{@forceline_load_fg_color},bg=#{@forceline_load_bg_color}] #{load_1min} #[default] | #[fg=#{@forceline_vcs_fg_color},bg=#{@forceline_vcs_bg_color}] #{vcs_branch} #[default] | #[fg=#{@fl_fg},bg=#{@fl_surface_0}] #{datetime_time} #[default]"
```

## Color System

### Base24 Color Palette
- **base00-base07**: Grayscale colors (darkest to lightest)
- **base08**: Red (error, deletion)
- **base09**: Orange (warning, modification)
- **base0A**: Yellow (attention, highlight)
- **base0B**: Green (success, addition)
- **base0C**: Cyan (info, secondary)
- **base0D**: Blue (primary, links)
- **base0E**: Magenta (accent, special)
- **base0F**: Brown (deprecated, muted)

### Semantic Aliases
- `@fl_primary`: Primary brand color (base0D)
- `@fl_secondary`: Secondary color (base0E)
- `@fl_success`: Success/positive color (base0B)
- `@fl_warning`: Warning/caution color (base09)
- `@fl_error`: Error/danger color (base08)
- `@fl_info`: Information color (base0C)

## Advanced Usage

### Custom Plugins
Create custom plugins in `~/.config/tmux/forceline/plugins/`:

```tmux
# vim:set ft=tmux:
# Custom Plugin Example

%hidden MODULE_NAME="custom"

set -g @_fl_plugin_custom_version "1.0.0"
set -g @_fl_plugin_custom_description "Custom functionality"

set -ogq "@forceline_${MODULE_NAME}_icon" "󰀄 "
set -ogq "@forceline_${MODULE_NAME}_text" " Custom Text"
set -ogq "@forceline_${MODULE_NAME}_text_fg" "#{@fl_fg}"
set -ogq "@forceline_${MODULE_NAME}_text_bg" "#{@fl_surface_0}"

source -F "#{d:current_file}/../../utils/status_module.conf"
```

### Performance Tuning
```tmux
# Update intervals
set -g @forceline_update_interval "1"
set -g @forceline_cache_enabled "yes"
set -g @forceline_cache_ttl "5"

# Specific module intervals
set -g @forceline_cpu_update_interval "2"
set -g @forceline_wan_ip_cache_ttl "900"
```

## Troubleshooting

### Debug Mode
```tmux
set -g @forceline_debug_modules "yes"
```

### Check Plugin Status
```bash
tmux show-options -g | grep @_fl_plugins
```

### Test Individual Modules
```bash
# Test CPU module
~/.config/tmux/plugins/tmux-forceline/modules/cpu/scripts/cpu_percentage.sh

# Test VCS module
~/.config/tmux/plugins/tmux-forceline/modules/vcs/scripts/vcs_branch.sh
```

## Migration from tmux-powerline

tmux-forceline v2.0 provides superior functionality compared to tmux-powerline:

- **Enhanced Performance**: Intelligent caching and optimized scripts
- **Better Cross-Platform Support**: Native support for Linux, macOS, BSD
- **Modern Icons**: Nerd Font icons throughout
- **Dynamic Colors**: Status-based color changes
- **Modular Architecture**: Enable only needed functionality

### Migration Steps
1. Replace tmux-powerline configuration with tmux-forceline
2. Update variable names (see compatibility table in docs)
3. Configure desired modules in `@forceline_plugins`
4. Customize colors using Base24 system

## Contributing

### Adding New Modules
1. Create module directory in `modules/`
2. Implement scripts following existing patterns
3. Create plugin configuration in `plugins/core/` or `plugins/extended/`
4. Add to plugin registry in `plugin_loader.conf`
5. Document in README.md

### Testing
```bash
# Test module scripts
./modules/[module]/scripts/[script].sh

# Test plugin loading
tmux source plugins/[category]/[module]/[module].conf
```

## License

[License information]

## Credits

Built upon concepts from tmux-powerline with significant enhancements and modern architecture.