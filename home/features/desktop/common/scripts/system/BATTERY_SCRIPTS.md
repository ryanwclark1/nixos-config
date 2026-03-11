# Battery Scripts Documentation

## Overview

The battery scripts have been consolidated into a shared library architecture for better maintainability, consistency, and robustness. All battery-related scripts now use a common detection library with multiple fallback methods.

## Architecture

### Shared Library: `os-battery-lib.sh`

The core library provides robust battery detection using multiple methods in order of preference:

1. **acpi** - Most detailed, includes time estimates
2. **/sys/class/power_supply/** - Direct kernel interface
3. **upower** - DBus-based, works on most systems

#### Key Functions

- `get_battery_percentage()` - Returns battery percentage (0-100) with automatic fallback
- `get_battery_state()` - Returns normalized state (Charging, Discharging, Full, Unknown)
- `get_battery_device()` - Returns battery device identifier
- `has_battery()` - Checks if system has a battery (returns 0 if yes, 1 if no)

### Utility Scripts

All utility scripts source the shared library and provide fallback behavior if the library is unavailable:

- **`os-battery-remaining.sh`** - Returns battery percentage as integer
  ```bash
  os-battery-remaining  # Output: 85
  ```

- **`os-battery-device.sh`** - Returns battery device identifier
  ```bash
  os-battery-device  # Output: BAT0
  ```

- **`os-battery-state.sh`** - Returns battery state
  ```bash
  os-battery-state  # Output: Charging, Discharging, Full, or Unknown
  ```

- **`os-battery-monitor.sh`** - Systemd timer script for low battery alerts
  - Configurable threshold via `BATTERY_THRESHOLD` environment variable (default: 10%)
  - Prevents notification spam using flag file
  - Automatically detects desktop systems (no battery) and exits silently

### Application Scripts

- **`rofi-os-battery.sh`** - Interactive Rofi applet for battery status and power management
  - Located in `~/.config/desktop/window-managers/shared/scripts/rofi/`
  - Available as `os-battery-rofi` command
  - Uses shared library for battery detection
  - Still extracts time estimates from acpi when available
  - Handles both desktop and laptop systems
  - Provides power management tool launching

- **`os-battery-show.sh`** - Simple notification-based battery status display
  - Uses shared library for battery detection
  - Provides fallback to direct /sys access if library unavailable

## Usage Examples

### Command Line

```bash
# Get battery percentage
os-battery-remaining

# Get battery state
os-battery-state

# Get battery device
os-battery-device

# Monitor battery (for systemd timer)
BATTERY_THRESHOLD=15 os-battery-monitor
```

### In Scripts

```bash
#!/usr/bin/env bash
source "$HOME/.local/bin/scripts/system/os-battery-lib.sh"

if has_battery; then
    percentage=$(get_battery_percentage)
    state=$(get_battery_state)
    echo "Battery: ${percentage}% (${state})"
else
    echo "No battery detected (desktop system)"
fi
```

## Integration

### NixOS Configuration

The scripts are automatically made available via:

1. **Direct commands in PATH** (via `writeShellScriptBin`):
   - `os-battery-remaining`
   - `os-battery-device`
   - `os-battery-state`
   - `os-battery-monitor`

2. **Script files in `~/.local/bin/scripts/system/`**:
   - All scripts including the shared library are copied here
   - Available for direct execution or sourcing

### Systemd Service

The `battery-monitor.nix` module uses `os-battery-monitor.sh` with configurable threshold:

```nix
features.battery-monitor = {
  enable = true;
  threshold = 15;  # Overrides default 10%
  interval = 30;   # Check every 30 seconds
};
```

## Benefits of Consolidation

1. **Consistency** - All scripts use the same detection logic
2. **Robustness** - Multiple fallback methods ensure battery detection works across systems
3. **Maintainability** - Single source of truth for battery detection
4. **Extensibility** - Easy to add new detection methods or features
5. **Error Handling** - Centralized validation and error handling

## Migration Notes

### For Existing Scripts

If you have custom scripts using battery detection:

**Before:**
```bash
BATTERY_LEVEL=$(upower -i $(upower -e | grep 'BAT') | grep -E "percentage" | awk '{print $2}' | sed 's/%//')
```

**After:**
```bash
source "$HOME/.local/bin/scripts/system/os-battery-lib.sh"
BATTERY_LEVEL=$(get_battery_percentage)
```

### For Systemd Services

The `battery-monitor.nix` service now uses the shared script. If you have custom systemd services, update them to use `os-battery-monitor.sh` or the shared library functions.

## Troubleshooting

### Script Not Found

Ensure scripts are in PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Library Not Found

The scripts include fallback behavior if the library is unavailable. If you see warnings, ensure:
1. Scripts are installed via NixOS configuration
2. `~/.local/bin/scripts/system/os-battery-lib.sh` exists

### Detection Issues

The shared library tries multiple methods automatically. If battery detection fails:
1. Check if `acpi`, `upower`, or `/sys/class/power_supply/` are available
2. Verify battery hardware is detected: `ls /sys/class/power_supply/`
3. Test individual methods: `acpi -b`, `upower -e | grep BAT`

## Future Improvements

- [x] Update `os-battery-show.sh` to use shared library
- [ ] Add battery time estimation to shared library
- [ ] Add battery health/cycle count detection
- [ ] Support for multiple batteries
- [ ] Add unit tests for shared library functions
