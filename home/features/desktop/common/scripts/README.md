# Desktop Scripts Organization

This directory contains scripts organized by scope and compatibility level, following a logical hierarchy for maintainability and reusability.

## Directory Structure

```
~/.local/bin/scripts/
├── system/              # System-level scripts (DE/WM independent)
├── wayland/             # Wayland compositor scripts  
└── rofi/                # Rofi menu scripts (WM independent)

~/.config/hypr/scripts/  # Hyprland-specific scripts
├── hypr/                # Hyprland compositor specific
└── system/              # System integration for Hyprland
```

## Script Categories

### System-Level Scripts (`~/.local/bin/scripts/system/`)
Platform and window manager independent utilities:

- **`volume.sh`** - Audio volume control with rofi interface
- **`brightness.sh`** - Display brightness control with rofi interface  
- **`power.sh`** - Power management (lock/logout/suspend/reboot/shutdown)
- **`launch-webapp.sh`** - Web application launcher with UWSM support

**Dependencies**: Core system utilities, optional rofi/notifications
**Usage**: Works with any desktop environment or window manager

### Wayland Scripts (`~/.local/bin/scripts/wayland/`)
Wayland compositor compatible utilities:

- **`screenshot.sh`** - Advanced screenshot tool (grimblast/grim+slurp)
- **`clipboard-manager.sh`** - Clipboard history management (cliphist)

**Dependencies**: Wayland compositor, wayland-specific tools
**Usage**: Works with any Wayland compositor (Hyprland, Sway, etc.)

### Rofi Scripts (`~/.local/bin/scripts/rofi/`)
Rofi-based menu interfaces:

- **`web-search.sh`** - Web search engine launcher

**Dependencies**: rofi, xdg-utils
**Usage**: Compatible with any window manager that supports rofi

### Hyprland-Specific Scripts (`~/.config/hypr/scripts/`)
Hyprland compositor specific functionality:

- **`hypr/`** - Scripts using `hyprctl` commands
- **`system/`** - Hyprland system integration scripts

## Configuration Integration

### Global Variables
Defined in `~/.config/hypr/conf/variables.conf`:

```bash
# Common script paths (organized by scope)
$SYSTEM_SCRIPTS = ~/.local/bin/scripts/system
$WAYLAND_SCRIPTS = ~/.local/bin/scripts/wayland  
$ROFI_SCRIPTS = ~/.local/bin/scripts/rofi
$HYPR_SCRIPTS = ~/.config/hypr/scripts
```

### Keybinding Examples
```bash
# System-level power management
bind = $mainMod, Escape, exec, $SYSTEM_SCRIPTS/power.sh

# Wayland screenshot
bind = , Print, exec, $WAYLAND_SCRIPTS/screenshot.sh area

# Rofi web search
bind = $mainMod, W, exec, $ROFI_SCRIPTS/web-search.sh

# Hyprland-specific functionality
bind = $mainMod, F1, exec, $HYPR_SCRIPTS/hyprland-keybindings.sh
```

## Script Features

### Enhanced Error Handling
All reorganized scripts include:
- Comprehensive dependency checking
- Graceful error handling with user feedback
- Logging and notification support
- Help/usage information

### Modern Shell Practices
- Use of `set -euo pipefail` for safety
- Proper variable quoting and validation
- Modular function design
- Configuration file support

### Cross-Platform Compatibility
- Automatic tool detection with fallbacks
- Environment-aware functionality
- Configurable behavior through environment variables

## Migration Notes

### Path Updates
Scripts have been moved from the old flat structure:
```bash
# Old paths
~/.config/hypr/scripts/system/volume.sh
~/.config/hypr/scripts/rofi/web-search.sh

# New paths  
~/.local/bin/scripts/system/volume.sh
~/.local/bin/scripts/rofi/web-search.sh
```

### Configuration Updates
- Updated variable definitions in `variables.conf`
- Updated keybinding references in `keybindings/default.conf`
- Updated autostart script paths in `autostart.conf`

## Usage Examples

### Direct Execution
```bash
# System volume control
~/.local/bin/scripts/system/volume.sh

# Screenshot with area selection
~/.local/bin/scripts/wayland/screenshot.sh area

# Power menu
~/.local/bin/scripts/system/power.sh
```

### Command Line Options
All scripts support `--help` for usage information:
```bash
~/.local/bin/scripts/system/volume.sh --help
~/.local/bin/scripts/wayland/screenshot.sh --help
```

### Integration with Session Managers
Scripts are designed to work with:
- UWSM (Universal Wayland Session Manager)
- systemd user services
- Traditional desktop environments

## Dependencies

### Core Dependencies
- `bash` (>= 4.0)
- `coreutils` (mkdir, chmod, etc.)

### Feature-Specific Dependencies
- **Audio Control**: `wpctl` (PipeWire/WirePlumber)
- **Brightness**: `light`, `brightnessctl`, or `xbacklight`
- **Screenshots**: `grimblast` or `grim`+`slurp`  
- **Clipboard**: `cliphist`, `wl-clipboard`
- **Rofi Interfaces**: `rofi`
- **Notifications**: `notify-send` (optional)
- **Web Apps**: Browser with `--app` mode support

## Contributing

When adding new scripts:
1. Choose appropriate directory based on scope/dependencies
2. Follow the established error handling patterns
3. Include comprehensive help text
4. Test across different environments
5. Update this documentation

## Troubleshooting

### Script Not Found
Ensure `~/.local/bin` is in your PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Permission Errors
Make scripts executable:
```bash
chmod +x ~/.local/bin/scripts/**/*.sh
```

### Dependency Issues
Scripts will report missing dependencies on first run. Install required packages through your system package manager.