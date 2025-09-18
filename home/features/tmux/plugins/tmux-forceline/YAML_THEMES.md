# YAML Theme System for tmux-forceline v2.0

## Overview

tmux-forceline v2.0 features a comprehensive YAML-based theme system built on the Base24 color specification. This provides a standardized, portable way to define and share themes across different applications with a clean, modern architecture.

## Base24 Color System

The Base24 specification extends Base16 with 8 additional colors, providing 24 standardized colors total:

### Core Colors (Base16 Compatible)
- **base00-base07**: Grayscale colors (darkest to lightest)
- **base08**: Red (error, deletion)
- **base09**: Orange (warning, modification)  
- **base0A**: Yellow (attention, highlight)
- **base0B**: Green (success, addition)
- **base0C**: Cyan (info, secondary)
- **base0D**: Blue (primary, links)
- **base0E**: Magenta (accent, special)
- **base0F**: Brown (deprecated, muted)

### Extended Colors (Base24 Specific)
- **base10**: Darker background
- **base11**: Darkest background
- **base12**: Bright red
- **base13**: Bright yellow
- **base14**: Bright green
- **base15**: Bright cyan
- **base16**: Bright blue
- **base17**: Bright purple

## YAML Theme Structure

### Required Fields

```yaml
system: "base24"              # Must be "base24"
name: "Theme Display Name"    # Human-readable theme name
author: "Author Information"  # Theme creator (optional but recommended)
variant: "dark"              # "dark" or "light"
palette:                     # Color definitions (all base00-base17 required)
  base00: "#000000"          # Must be valid hex colors
  # ... (all 24 colors)
  base17: "#ffffff"
```

### Validation

The YAML theme parser automatically validates:
- ✅ Required fields presence
- ✅ Base24 system specification
- ✅ All 24 colors defined
- ✅ Valid hex color format
- ✅ File accessibility and syntax

## Available Themes

### Predefined YAML Themes

| Theme | Variant | Description |
|-------|---------|-------------|
| `catppuccin-frappe` | dark | Soothing pastel theme (default) |
| `catppuccin-mocha` | dark | Darker Catppuccin variant |
| `dracula` | dark | Popular dark theme with vibrant colors |
| `nord` | dark | Arctic, north-bluish color palette |
| `gruvbox-dark` | dark | Retro groove warm color scheme |

### Theme Selection

```tmux
# Use predefined YAML theme
set -g @forceline_theme "catppuccin-frappe"

# Explicitly specify YAML format (optional)
set -g @forceline_theme_format "yaml"
```

## Custom Themes

### Creating Custom YAML Themes

1. **Create YAML file** following Base24 specification:

```yaml
system: "base24"
name: "My Custom Theme"
author: "Your Name <email@example.com>"
variant: "dark"
palette:
  base00: "#1a1a1a" # background
  base01: "#2a2a2a" # mantle
  base02: "#3a3a3a" # surface0
  base03: "#4a4a4a" # surface1
  base04: "#5a5a5a" # surface2
  base05: "#e0e0e0" # text
  base06: "#f0f0f0" # rosewater
  base07: "#ffffff" # lavender
  base08: "#ff6b6b" # red
  base09: "#ffa500" # orange
  base0A: "#ffff00" # yellow
  base0B: "#51cf66" # green
  base0C: "#22b8cf" # cyan
  base0D: "#4c6ef5" # blue
  base0E: "#cc5de8" # magenta
  base0F: "#795548" # brown
  base10: "#0f0f0f" # darker background
  base11: "#050505" # darkest background
  base12: "#ff8a80" # bright red
  base13: "#ffff8d" # bright yellow
  base14: "#69f0ae" # bright green
  base15: "#18ffff" # bright cyan
  base16: "#82b1ff" # bright blue
  base17: "#ea80fc" # bright purple
```

2. **Configure tmux to use custom theme**:

```tmux
set -g @forceline_theme "custom"
set -g @forceline_theme_format "yaml"
set -g @forceline_custom_theme_path "~/.config/tmux/themes/my-theme.yaml"
```


## Theme Management Tools

### YAML Parser Script

The `themes/scripts/yaml_parser.sh` script provides theme management utilities:

```bash
# List available YAML themes
./yaml_parser.sh list

# Validate YAML theme structure
./yaml_parser.sh validate my-theme.yaml

# Convert YAML to tmux config
./yaml_parser.sh convert my-theme.yaml output.conf

# Generate tmux config from theme name
./yaml_parser.sh generate catppuccin-frappe
```

### Theme Generation

YAML themes are automatically converted to tmux configuration files when loaded:

- Source: `themes/yaml/theme-name.yaml`
- Generated: `themes/generated/theme-name.conf`
- Cached until YAML file changes

## Semantic Color Aliases

All themes automatically provide semantic color aliases:

### Interface Colors
```tmux
@fl_bg           # Background (base00)
@fl_fg           # Foreground (base05)
@fl_surface_0    # Surface level 0 (base01)
@fl_surface_1    # Surface level 1 (base02)
@fl_surface_2    # Surface level 2 (base03)
@fl_muted        # Muted text (base04)
@fl_subtle       # Subtle text (base06)
@fl_text         # High contrast text (base07)
```

### Semantic Colors
```tmux
@fl_error        # Red - Error states (base08)
@fl_warning      # Orange - Warning states (base09)
@fl_attention    # Yellow - Attention (base0A)
@fl_success      # Green - Success states (base0B)
@fl_info         # Cyan - Information (base0C)
@fl_primary      # Blue - Primary accent (base0D)
@fl_secondary    # Magenta - Secondary accent (base0E)
@fl_accent       # Brown - Accent color (base0F)
```

### Extended Colors
```tmux
@fl_mantle       # Darker background (base10)
@fl_crust        # Darkest background (base11)
@fl_bright_red   # Bright red (base12)
@fl_bright_yellow # Bright yellow (base13)
@fl_bright_green # Bright green (base14)
@fl_bright_cyan  # Bright cyan (base15)
@fl_bright_blue  # Bright blue (base16)
@fl_bright_purple # Bright purple (base17)
```

## Usage in Status Lines

### Using Semantic Colors

```tmux
# Recommended: Use semantic aliases
set -g status-left "#[fg=#{@fl_base00},bg=#{@fl_primary}] Host #[default]"
set -g status-right "#[fg=#{@fl_fg},bg=#{@fl_surface_0}] Time #[default]"
```

### Using Direct Base24 Colors

```tmux
# Direct Base24 references (advanced)
set -g status-left "#[fg=#{@fl_base00},bg=#{@fl_base0D}] Host #[default]"
```

### Dynamic Module Colors

```tmux
# Module-specific dynamic colors
set -g status-right "#[fg=#{@forceline_cpu_fg_color},bg=#{@forceline_cpu_bg_color}] #{cpu_percentage} #[default]"
```

## Troubleshooting

### Common Issues

**1. "yq not found" message**
```bash
# Install yq for YAML support
brew install yq  # macOS
sudo snap install yq  # Linux
```

**2. Theme not loading**
```bash
# Check YAML syntax
./themes/scripts/yaml_parser.sh validate your-theme.yaml

# Verify file path
ls -la ~/.config/tmux/themes/
```

**3. Colors not updating**
```bash
# Force regeneration
rm themes/generated/*.conf
tmux source-file ~/.tmux.conf
```

### Debug Information

```tmux
# Check theme loading status
tmux show-options -g | grep @forceline_theme
tmux show-options -g | grep @_fl_yq_available

# View theme metadata
tmux show-options -g | grep @fl_theme_
```

## Requirements

tmux-forceline v2.0 requires `yq` for YAML theme processing:

```bash
# macOS with Homebrew
brew install yq

# Linux with snap
sudo snap install yq

# Or download binary from https://github.com/mikefarah/yq#install
```

If `yq` is not available, tmux-forceline will display an error message with installation instructions.

## Contributing Themes

### Theme Submission Guidelines

1. **Follow Base24 specification** exactly
2. **Provide meaningful color assignments** for all 24 colors
3. **Include proper metadata** (name, author, variant)
4. **Test thoroughly** with various modules
5. **Submit pull request** with theme file and documentation

### Theme Testing Checklist

- [ ] All 24 colors defined and valid
- [ ] Semantic aliases work correctly
- [ ] Readable contrast ratios
- [ ] Module colors display properly
- [ ] Works in various terminal environments
- [ ] Validates with `yaml_parser.sh validate`

## Examples

See the `examples/` directory for:
- `custom-theme-yaml.yaml` - Complete custom theme template
- `custom-theme-config.tmux` - Configuration examples
- Theme usage in different scenarios

The YAML theme system provides a powerful, standardized way to customize tmux-forceline appearance while maintaining compatibility and ease of use.