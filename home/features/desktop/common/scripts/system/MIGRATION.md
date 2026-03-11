# Script Co-location Migration

## Summary

Wayland scripts have been co-located with system scripts for better organization and documentation.

## Changes Made

### Scripts Moved
- `wayland/scripts/screenrecord.sh` → `system/screenrecord-wayland.sh`
- `wayland/scripts/screenrecord-stop.sh` → `system/screenrecord-wayland-stop.sh`
- `wayland/scripts/screenrecord-toggle.sh` → `system/screenrecord-wayland-toggle.sh`
- `wayland/scripts/clipboard-manager.sh` → `system/clipboard-manager.sh`

### Scripts Kept in Wayland Directory
- `wayland/scripts/screenshot.sh` - Kept in wayland directory as it's a Wayland-specific utility

### Documentation Added
- `SCREENRECORDING.md` - Comprehensive documentation comparing all screen recording and screenshot scripts

### Scripts Updated
- All scripts now include header comments referencing the documentation
- `os-cmd-screenshot.sh` updated to find `screenshot.sh` in wayland directory
- `screenrecord-wayland-toggle.sh` updated to reference correct script names
- `screenrecording-indicator.sh` updated to detect both recording tools

### Configuration Updated
- `scripts/wayland/default.nix` updated to source scripts from new location
- Backward compatibility maintained: legacy `wayland/scripts/` directory still deployed

## Current Status

The `wayland/scripts/` directory is the primary location for:
- `screenshot.sh` - Wayland screenshot utility (stays in wayland directory)
- Legacy compatibility for other scripts that were migrated

## Migration Path

1. ✅ Screen recording scripts co-located to system/
2. ✅ Screenshot script kept in wayland/ (Wayland-specific utility)
3. ✅ Documentation created
4. ✅ Headers updated
5. ✅ Configuration updated
6. ✅ Wrapper scripts updated to reference correct locations

## Usage

See `SCREENRECORDING.md` for detailed usage instructions and comparisons.
