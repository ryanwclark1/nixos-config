# Hyprland Keybinding Analysis Report

## Overview
This document provides a comprehensive analysis of all keybindings across the modular configuration files to ensure no conflicts and optimal organization.

## File Organization
The keybindings are organized into 6 modular files:
1. **mouse.conf** - Mouse bindings (2 bindings)
2. **window.conf** - Window management, navigation, focus, resizing (30 bindings)
3. **workspace.conf** - Workspace switching and management (28 bindings)
4. **applications.conf** - Application launchers and rofi menus (22 bindings)
5. **media.conf** - Media keys, volume, brightness (15 bindings)
6. **system.conf** - System controls, power, screenshots (15 bindings)

**Total: ~112 keybindings**

## Conflict Analysis

### ✅ No Conflicts Found
All key combinations are unique. Different modifier combinations (SUPER, SUPER+SHIFT, SUPER+CTRL, SUPER+ALT) are properly used to avoid conflicts.

### ⚠️ Duplicate Functionality (Not Conflicts)
These keybindings perform the same function but use different keys:

1. **Keybindings Menu** (2 bindings):
   - `SUPER+F1` → `qs-rofi -show keybinds`
   - `SUPER+K` → `qs-rofi -show keybinds`
   - **Recommendation**: Keep both for accessibility, or remove F1 if K is preferred

2. **Rofi Application Launcher** (3 bindings):
   - `SUPER+SPACE` → `qs-rofi -show drun`
   - `SUPER+X` → `rofi -show drun` (different command)
   - `SUPER+Z` → `qs-rofi -show drun`
   - **Recommendation**: Consider consolidating to one primary binding (SUPER+SPACE)

## Keybinding Categories

### Application Launchers (applications.conf)
- **Terminal**: `SUPER+Return` → kitty
- **Editor**: `SUPER+E` → code
- **Browser**: `SUPER+B` → google-chrome
- **File Manager**: `SUPER+N` → nautilus
- **Rofi Menus**: Multiple bindings for different rofi functions

### Window Management (window.conf)
- **Close**: `SUPER+Q`, `ALT+F4`
- **Fullscreen**: `SUPER+F` (full), `SUPER+SHIFT+F` (windowed), `SUPER+M` (windowed)
- **Navigation**: Vim keys (H/J/K/L) + Arrow keys
- **Resize**: `SUPER+CTRL+H/J/K/L` or Arrow keys
- **Window Switcher**: `SUPER+Tab` → Quickshell Overview

### Workspace Management (workspace.conf)
- **Switch**: `SUPER+1-9,0` (number keys) or `SUPER+KP_1-KP_0` (numpad)
- **Move Window**: `SUPER+SHIFT+1-9,0` or `SUPER+SHIFT+KP_1-KP_0`
- **Previous**: `SUPER+apostrophe`, `SUPER+CTRL+Tab`
- **Scratchpad**: `SUPER+U` (toggle), `SUPER+SHIFT+U` (move to)
- **VM Passthrough**: `SUPER+P` → enter passthrough mode

### System Controls (system.conf)
- **Screenshot**: `Print`, `SUPER+S` (area)
- **OCR Screenshot**: `ALT+Print`
- **Quickshell Panels**: Multiple bindings for Control Center, Notifications, Settings
- **System Menu**: `SUPER+SHIFT+Escape` → system menu

### Media Keys (media.conf)
- **Playback**: `XF86AudioNext/Prev/Play/Stop`
- **Volume**: `XF86AudioRaiseVolume/LowerVolume/Mute`
- **Brightness**: `XF86MonBrightnessUp/Down`
- **Mic Control**: `SHIFT+XF86Audio*` for microphone

## Organization Quality

### ✅ Strengths
1. **Clear separation** by functionality (window, workspace, applications, etc.)
2. **Consistent naming** and formatting
3. **Good comments** explaining purpose
4. **Logical grouping** within each file
5. **Modifier key consistency** (SUPER for primary, SHIFT for modify, CTRL for control)

### 🔧 Areas for Improvement
1. **Consolidate duplicate rofi launchers** - Consider removing redundant bindings
2. **Standardize comments** - Some have "(Omarchy)" tags, others don't
3. **Documentation** - Could add more inline comments explaining key choices
4. **Keybinding reference** - Consider generating a reference document

## Recommendations

### Immediate Actions
1. ✅ **No conflicts** - Configuration is safe to use
2. 🔧 **Optional cleanup**: Remove redundant rofi launcher bindings (SUPER+X, SUPER+Z) if SUPER+SPACE is sufficient
3. 📝 **Documentation**: Add a keybinding reference file for quick lookup

### Future Enhancements
1. Generate a visual keybinding reference
2. Add keybinding categories to comments for easier navigation
3. Consider adding keybinding search functionality
4. Create a keybinding conflict checker script

## Keybinding Patterns

### Modifier Usage
- **SUPER alone**: Primary actions (launch apps, window operations)
- **SUPER+SHIFT**: Modify behavior (move windows, move to workspace)
- **SUPER+CTRL**: Control operations (reload, resize, system controls)
- **SUPER+ALT**: Alternative actions (nautilus, passthrough mode)

### Key Groups
- **Letters**: Application launchers and common actions
- **Numbers**: Workspace switching (1-9, 0 for 10)
- **Function Keys**: Special functions (F1 for keybinds)
- **Media Keys**: Hardware keys (XF86Audio*, XF86MonBrightness*)
- **Special**: Tab, Space, Escape, Return, etc.

## Conclusion
The keybinding configuration is well-organized with no conflicts. The modular structure makes it easy to maintain and extend. Minor improvements could be made by consolidating duplicate functionality, but the current setup is functional and safe.
