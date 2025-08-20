# Hyprland Scripts - Enhanced & Consolidated

This directory contains organized and consolidated scripts for Hyprland desktop environment management.

## 📁 Structure

```
scripts/
├── rofi/              # Rofi menus and launchers
├── hypr/              # Hyprland-specific functionality  
├── system/            # System utilities
└── [compatibility]    # Backward compatibility layer
```

## 🆕 Enhanced Scripts

### **Unified Power Menu** (`rofi/powermenu-unified.sh`)
- Consolidates 3 different power menus into one configurable script
- Supports multiple themes via environment variables
- Enhanced error handling and fallback options
- Features: shutdown, reboot, lock, suspend, hibernate, logout

### **Enhanced Wallpaper Manager** (`hypr/wallpaper-manager.sh`)
- Replaces 4 separate wallpaper scripts
- Features:
  - Set specific/random wallpapers
  - Automatic rotation with configurable intervals
  - Effects management (blur, etc.)
  - Cache generation and management
  - Restore last wallpaper
- Better error handling and logging

### **Hyprland Utilities** (`system/hypr-utils.sh`)
- Consolidates 6 small utility scripts into one tool
- Features:
  - Play clipboard URLs in mpv
  - Restart hypridle daemon
  - Toggle rofi launcher
  - Clear wallpaper cache
  - Launch wlogout with dynamic sizing
  - Show system information
- Configurable via environment variables

### **Clipboard Management** (`rofi/cliphist.sh`)
- Kept the most comprehensive clipboard script
- Removed 2 redundant simple scripts
- Features: copy, delete, wipe clipboard history

### **Unified Application Launchers** (`rofi/apps-unified.sh`)
- Replaces both `apps.sh` and `appasroot.sh` with consistent approach
- User mode: Terminal, File Manager, Code Editor, Browser, Music, Settings
- Root mode: Root Terminal, File Manager (Root), System Editor, Services, Logs, Disk Management
- Features: Proper icons, appropriate applications, working pkexec integration

### **Settings Menu** (`rofi/settings-menu.sh`)
- Comprehensive settings manager for Hyprland users
- Audio (pwvucontrol), Bluetooth (blueman), Network, Display, Themes, System info
- Better than `xfce4-settings-manager` for Wayland/Hyprland environment

## 🔄 Direct Integration

All configurations now reference the unified scripts directly:

- **Power management**: `rofi/powermenu-unified.sh` with proper Nerd Font icons (󰐥󰜉󰌾󰏦󰍃)
- **Screenshot menu**: `rofi/screenshot-menu.sh` with options for area/screen/window/clipboard/OCR
- **Wallpaper management**: `hypr/wallpaper-manager.sh` for all wallpaper operations
- **Workspace switching**: `hypr/workspace-switcher.sh` with preview support
- **System utilities**: `system/hypr-utils.sh` and `system/power.sh` for wlogout integration

## 📊 Improvements Summary

| Category | Before | After | Reduction |
|----------|--------|-------|-----------|
| Total Scripts | 44+ | 34 | -23% |
| Power Menus | 3 | 1 | -67% |
| Wallpaper Scripts | 5 | 1 | -80% |
| Clipboard Scripts | 3 | 1 | -67% |
| Utility Scripts | 6 | 1 | -83% |
| Workspace Scripts | 2 | 1 | -50% |
| App Launchers | 2 | 1 | -50% |

**Key Improvements:**
- ✅ **Zero legacy scripts** - Clean codebase with no compatibility baggage
- ✅ **Enhanced functionality** - Proper icons, rofi menus, and advanced features  
- ✅ **Consistent naming** - All scripts use kebab-case naming convention
- ✅ **Improved UX** - Modern settings management and app launchers
- ✅ **Direct integration** - All configs reference unified scripts without redirects

## 🚀 New Features Added

1. **Configuration Support**: Environment variables for customization
2. **Error Handling**: Proper error checking and fallbacks
3. **Logging**: Structured logging for debugging
4. **Help System**: Built-in help for all scripts
5. **Modular Design**: Functions can be called individually
6. **Resource Efficiency**: Reduced script count and complexity

## 🔧 Environment Variables

### Wallpaper Manager
- `HYPR_WALLPAPER_DIR`: Wallpaper directory (default: ~/Pictures/wallpapers)

### Utilities
- `HYPR_NOTIFICATION_TIMEOUT`: Notification duration (default: 3000ms)
- `HYPR_MPV_FLAGS`: MPV flags (default: --no-terminal --force-window)

### Power Menu
- `ROFI_POWERMENU_STYLE`: Theme type (default: type-3)
- `ROFI_POWERMENU_STYLE_NAME`: Theme name (default: style-3)
- `POWERMENU_*_ICON`: Custom icons for each action

## 📝 Usage Examples

```bash
# Enhanced wallpaper management
./hypr/wallpaper-manager.sh random
./hypr/wallpaper-manager.sh automation start 30
./hypr/wallpaper-manager.sh effect blur

# Utility functions
./system/hypr-utils.sh play-clipboard
./system/hypr-utils.sh restart-hypridle
./system/hypr-utils.sh clear-cache

# Power menu (all variants work)
./rofi/powermenu-unified.sh
./powermenu.sh  # compatibility link
./power-big.sh  # compatibility link
```

## 🔗 Integration

All existing configuration files continue to work without changes due to the compatibility layer. The enhanced scripts provide better functionality while maintaining full backward compatibility.