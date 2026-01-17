# Screenshot Scripts Consolidation

## Overview

This document describes the consolidation of screenshot scripts across the NixOS configuration. Previously, there were multiple duplicate and overlapping screenshot scripts. They have been unified into a single comprehensive script with wrapper scripts for backward compatibility.

## Architecture

### Unified Script: `screenshot.sh`

**Location:** `home/features/desktop/common/scripts/wayland/screenshot.sh`

This is the main, comprehensive screenshot script that provides all screenshot functionality:

- **Backends:** Supports both `grimblast` (preferred) and `grim+slurp` (fallback)
- **Modes:**
  - `screen` / `fullscreen` - Capture entire screen
  - `area` / `region` - Interactive area selection
  - `window` - Capture active window
  - `smart` - Smart selection with window/output detection (auto-selects window if tiny selection)
  - `windows` - Select from visible windows
- **Features:**
  - Freeze mode (`--freeze`) - Freezes screen during selection
  - Wait/delay (`--wait TIME`) - Delays capture by specified seconds
  - Format selection (`--format png|jpg|webp`)
  - Satty integration (`--satty`) - Opens satty editor after capture
  - Clipboard-only mode (`--clipboard-only`) - Copies to clipboard without saving
  - Rich notifications with actions (view, edit, copy path, open folder)

### Wrapper Scripts

#### `os-cmd-screenshot`

**Location:** `home/features/desktop/common/scripts/system/os-cmd-screenshot`

Wrapper that maintains compatibility with the old `os-cmd-screenshot` interface:
- Maps old modes (`region`, `windows`, `fullscreen`, `smart`) to new modes
- Maps `PROCESSING` parameter (`slurp` → `--satty`, `clipboard` → `--clipboard-only`)
- Uses `OS_SCREENSHOT_DIR` environment variable for output directory

#### `omarchy-cmd-screenshot`

**Location:** `omarchy/bin/omarchy-cmd-screenshot`

Identical to `os-cmd-screenshot` except uses `OMARCHY_SCREENSHOT_DIR` environment variable. This maintains backward compatibility for the omarchy configuration.

### Hyprland-Specific: `screenshot-enhanced`

**Location:** `home/features/desktop/window-managers/shared/media/screenshot-enhanced.nix`

This Nix package provides Hyprland-specific screenshot tools using `hyprshot`:
- Uses `hyprshot` which is Hyprland-specific
- Provides simpler, more opinionated interface
- Packaged as Nix binaries for convenience
- Provides wrapper commands: `screenshot-region`, `screenshot-window`, `screenshot-output`

**Note:** This is kept separate because it uses Hyprland-specific tools (`hyprshot`) and provides a different workflow. The unified `screenshot.sh` can work with Hyprland but uses general Wayland tools.

## Migration Guide

### For Scripts Using `os-cmd-screenshot`

No changes needed! The wrapper maintains full backward compatibility:
```bash
os-cmd-screenshot smart        # Still works
os-cmd-screenshot smart clipboard  # Still works
```

### For Scripts Using `omarchy-cmd-screenshot`

No changes needed! The wrapper maintains full backward compatibility:
```bash
omarchy-cmd-screenshot smart        # Still works
omarchy-cmd-screenshot smart clipboard  # Still works
```

### For Direct Usage of `screenshot.sh`

The unified script supports all previous functionality plus new features:

```bash
# Old way (still works)
screenshot.sh area
screenshot.sh screen

# New features
screenshot.sh smart --freeze --satty
screenshot.sh windows --clipboard-only
screenshot.sh area --wait 3 --format jpg
```

## Key Improvements

1. **Single Source of Truth:** All screenshot logic is now in one place (`screenshot.sh`)
2. **Feature Parity:** All features from previous scripts are now available in the unified script
3. **Backward Compatibility:** Wrapper scripts ensure existing configurations continue to work
4. **Better Documentation:** Comprehensive help text and usage examples
5. **Enhanced Features:** New modes (`smart`, `windows`) and options (`--satty`, `--clipboard-only`)

## Environment Variables

- `SCREENSHOTS_DIR` - Output directory for unified script (default: `~/Pictures/Screenshots`)
- `OS_SCREENSHOT_DIR` - Output directory for `os-cmd-screenshot` wrapper
- `OMARCHY_SCREENSHOT_DIR` - Output directory for `omarchy-cmd-screenshot` wrapper
- `SCREENSHOT_DIR` - Output directory for `screenshot-enhanced` (Hyprland-specific)

## Dependencies

### Unified Script (`screenshot.sh`)
- `grimblast` (preferred) or `grim` + `slurp` (fallback)
- `wl-copy` (for clipboard)
- `notify-send` (for notifications)
- Optional: `satty` (for editing), `wayfreeze` (for freeze mode), `jq` (for smart mode)

### Wrapper Scripts
- Same as unified script (they call it)

### `screenshot-enhanced`
- `hyprshot` (Hyprland-specific)
- `satty` (for editing)
- `slurp` (for area selection)

## File Locations

```
home/features/desktop/common/scripts/
├── wayland/
│   └── screenshot.sh          # Unified script (MAIN)
└── system/
    └── os-cmd-screenshot       # Wrapper for backward compatibility

omarchy/bin/
└── omarchy-cmd-screenshot     # Wrapper for omarchy (backward compatibility)

home/features/desktop/window-managers/shared/media/
└── screenshot-enhanced.nix    # Hyprland-specific Nix package
```

## Testing

After consolidation, verify:
1. ✅ `os-cmd-screenshot smart` works
2. ✅ `omarchy-cmd-screenshot smart clipboard` works
3. ✅ `screenshot.sh area --satty` works
4. ✅ `screenshot.sh smart --freeze` works
5. ✅ All keybindings still function correctly

## Future Considerations

- Consider deprecating `screenshot-enhanced` in favor of unified script if Hyprland support improves
- Consider adding X11 support to unified script for broader compatibility
- Consider adding OCR functionality (currently only in keybindings)

