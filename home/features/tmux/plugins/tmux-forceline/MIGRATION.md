# tmux-forceline v2.0 Migration Guide

## Overview

tmux-forceline v2.0 represents a complete architectural rewrite with the following major changes:

- **Independent from catppuccin**: No longer depends on catppuccin color variables
- **Base24 theming**: Standardized 24-color palette system
- **Plugin ecosystem**: Modular, extensible plugin architecture  
- **Theme system**: Replaced "flavors" with proper theme management
- **Enhanced configuration**: More intuitive and powerful options

## Breaking Changes

### 1. Color Variables (⚠️ Breaking)

**Old (catppuccin-based):**
```tmux
@thm_bg, @thm_fg, @thm_red, @thm_green, etc.
```

**New (Base24):**
```tmux
@fl_base00-@fl_base17, @fl_bg, @fl_fg, @fl_primary, @fl_error, etc.
```

### 2. Theme Selection (⚠️ Breaking)

**Old:**
```tmux
set -g @forceline_flavor "mocha"
```

**New:**
```tmux
set -g @forceline_theme "catppuccin-frappe"  # or "dracula", "custom"
```

### 3. Plugin Configuration (⚠️ Breaking)

**Old:** Individual status module files
**New:** Plugin system with auto-discovery

```tmux
# Old: Manual sourcing of modules
# New: Plugin list
set -g @forceline_plugins "cpu,memory,battery,datetime"
```

### 4. Configuration Files (⚠️ Breaking)

**Old structure:**
```
forceline_options_tmux.conf
forceline_tmux.conf  
themes/catppuccin_*.conf
```

**New structure:**
```
forceline_options_new.conf
forceline_tmux_new.conf
themes/base24/*.conf
plugins/core/*/
plugins/extended/*/
```

## Migration Steps

### Step 1: Update Configuration Files

Replace your old configuration files:

```bash
# Backup current config
cp forceline_options_tmux.conf forceline_options_tmux.conf.backup
cp forceline_tmux.conf forceline_tmux.conf.backup

# Use new configuration
mv forceline_options_new.conf forceline_options_tmux.conf  
mv forceline_tmux_new.conf forceline_tmux.conf
```

### Step 2: Update Theme Selection

**Old configuration:**
```tmux
set -g @forceline_flavor "mocha"
```

**New configuration:**
```tmux
set -g @forceline_theme "catppuccin-frappe"
```

Available themes:
- `catppuccin-frappe` (default)
- `dracula`
- `custom` (requires `@forceline_custom_theme_path`)

### Step 3: Configure Plugins

Replace manual module configuration with plugin system:

**Old:**
```tmux
# Manual status line configuration
set -g status-right "#{@forceline_status_cpu}#{@forceline_status_battery}"
```

**New:**
```tmux
# Plugin-based configuration
set -g @forceline_plugins "cpu,memory,battery,datetime"
```

### Step 4: Update Custom Colors (if applicable)

If you have custom color overrides, update to Base24 variables:

**Old:**
```tmux
set -g @custom_color "#{@thm_red}"
```

**New:**
```tmux
set -g @custom_color "#{@fl_base08}"  # or #{@fl_error}
```

## Base24 Color Reference

| Base24 | Semantic | Description |
|--------|----------|-------------|
| `@fl_base00` | `@fl_bg` | Default background |
| `@fl_base01` | `@fl_mantle` | Lighter background |
| `@fl_base02` | `@fl_surface_0` | Selection background |
| `@fl_base03` | `@fl_surface_1` | Comments, disabled |
| `@fl_base04` | `@fl_surface_2` | Dark foreground |
| `@fl_base05` | `@fl_fg` | Default foreground |
| `@fl_base08` | `@fl_error` | Red/error |
| `@fl_base09` | `@fl_warning` | Orange/warning |
| `@fl_base0A` | `@fl_accent` | Yellow/accent |
| `@fl_base0B` | `@fl_success` | Green/success |
| `@fl_base0C` | `@fl_info` | Cyan/info |
| `@fl_base0D` | `@fl_primary` | Blue/primary |
| `@fl_base0E` | `@fl_secondary` | Purple/secondary |

## Plugin System

### Core Plugins (always available)
- `cpu` - CPU usage and temperature monitoring
- `memory` - RAM and swap usage  
- `battery` - Battery status and percentage
- `datetime` - Date and time display
- `session` - Session name and status
- `directory` - Current working directory

### Extended Plugins (opt-in)
- `weather` - Weather information
- `network` - Network status and IP
- `kubernetes` - K8s context and namespace
- `git` - Git branch and status
- `docker` - Docker container info

### Plugin Configuration

```tmux
# Enable specific plugins
set -g @forceline_plugins "cpu,memory,battery"

# Plugin-specific settings
set -g @forceline_cpu_temp_enabled "yes"
set -g @forceline_memory_format "percentage"
```

## Creating Custom Themes

### 1. Create Theme File

```bash
# Create custom theme
cat > ~/.config/tmux/forceline/themes/my-theme.conf << 'EOF'
# My Custom Theme - Base24
set -ogq @fl_base00 "#1e1e2e"  # background
set -ogq @fl_base05 "#cdd6f4"  # foreground
# ... define all Base24 colors
EOF
```

### 2. Configure Theme Path

```tmux
set -g @forceline_theme "custom"
set -g @forceline_custom_theme_path "~/.config/tmux/forceline/themes/my-theme.conf"
```

## Troubleshooting

### Colors Not Applying
1. Ensure theme is loaded: `tmux show -g @forceline_theme_loaded`
2. Check theme file exists and has correct Base24 variables
3. Reload configuration: `tmux source ~/.tmux.conf`

### Plugins Not Loading  
1. Enable debug mode: `set -g @forceline_debug_modules "yes"`
2. Check plugin paths exist
3. Verify plugin configuration syntax

### Missing Icons
- Ensure you have a Nerd Font installed
- Update terminal font configuration
- Test with: `echo "󰍛 󰘚 󰂄"` in terminal

## Rollback Plan

If migration fails, restore from backup:

```bash
cp forceline_options_tmux.conf.backup forceline_options_tmux.conf
cp forceline_tmux.conf.backup forceline_tmux.conf
tmux source ~/.tmux.conf
```

## Support

- Check `@forceline_theme_loaded` and `@forceline_active_plugins` variables
- Enable debug mode with `@forceline_debug_modules "yes"`
- Verify Base24 color variables are set: `tmux show -g @fl_base00`