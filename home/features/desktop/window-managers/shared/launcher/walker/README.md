# Walker Application Launcher Configuration

Walker is a fast, extensible application launcher and runner for Wayland/X11.

## Directory Structure

```
walker/
├── default.nix              # Main walker configuration and nix integration
├── README.md                # This file
├── config.toml              # Walker main configuration (inline in default.nix)
└── themes/                  # Walker theme files
    ├── catppuccin.css       # Catppuccin Mocha color scheme
    └── catppuccin.toml      # Catppuccin UI layout configuration
```

## Features Enabled

### Core Functionality
- **Application Launcher** - Launch desktop applications
- **Calculator** - Inline calculations with `=` prefix
- **File Finder** - Search files with `.` prefix
- **Emoji/Symbols** - Insert emojis with `:` prefix
- **Keybindings Help** - Show Hyprland keybindings
- **Window Switcher** - Switch between open windows
- **Clipboard History** - Access clipboard with `$` prefix (when used with cliphist)

### Configuration Highlights

#### Prefixes
- `.` - File search (uses fd)
- `:` - Emojis and symbols
- `=` - Calculator

#### Settings
- **Theme**: Catppuccin Mocha
- **Launch Prefix**: `uwsm app --` (proper UWSM session management)
- **Timeout**: 60 seconds
- **Max Entries**: 200
- **Hot Reload**: Enabled for theme changes

#### Disabled Features
These are hidden by default but can be enabled:
- Bookmarks
- Clipboard (use rofi instead - SUPER+V)
- Commands
- SSH connections
- Web search (use rofi web-search instead)
- Translation

## Usage

### Keybindings
- **SUPER+SPACE** - Launch walker (if using walker as primary launcher)
- **SUPER+X** - Launch walker (alternative)

### Inline Features
While walker is open, you can use these prefixes:

| Prefix | Function | Example |
|--------|----------|---------|
| `.` | Find files | `.myfile.txt` |
| `:` | Emojis | `:smile` |
| `=` | Calculator | `=2+2` |

### File Search
The file finder is configured to:
- Use `fd` for fast file searching
- Preview images
- Open parent directory with Alt+Enter: `xdg-open $(dirname ~/file)`

## Customization

### Enable Hidden Features

Edit `default.nix` and change `hidden = true` to `hidden = false` for:

```toml
[builtins.clipboard]
hidden = false  # Enable clipboard history in walker

[builtins.websearch]
hidden = false  # Enable web search
```

### Change Theme Colors

Edit the CSS color definitions in `themes/catppuccin.css`:

```css
@define-color base #303446;    /* Background */
@define-color text #c6d0f5;    /* Text color */
@define-color blue #8caaee;    /* Accent color */
```

### Adjust UI Layout

Edit `themes/catppuccin.toml` to change:
- Window size and position
- List height and width
- Icon sizes
- Margins and spacing

## Theme: Catppuccin Mocha

The Catppuccin Mocha theme provides:
- Dark color scheme optimized for readability
- Subtle transparency effects
- Smooth hover animations
- Consistent icon theming
- AI chat integration styling (if using AI features)

### Color Palette
- **Base**: #303446 (background)
- **Mantle**: #292c3c (secondary background)
- **Text**: #c6d0f5 (primary text)
- **Blue**: #8caaee (accents)
- **Green**: #a6d189 (success)
- **Red**: #e78284 (errors)

## Integration with Hyprland

Walker is launched via UWSM for proper systemd integration:

```nix
programs.walker = {
  enable = true;
  package = pkgs.walker;
  systemd.enable = true;  # Runs as systemd user service
};
```

Applications launched through walker use `uwsm app --` prefix, ensuring they:
- Run in the correct systemd scope
- Have proper environment variables
- Integrate with session management

## Hyprland Keybindings Integration

Walker can show Hyprland keybindings when configured:

```toml
[builtins.hyprland_keybinds]
path = "~/.config/hypr/hyprland.conf"
```

This allows you to search and view your Hyprland keybindings directly in walker.

## Tips

1. **Fast App Launch**: Just start typing the app name - no prefix needed
2. **Quick Math**: Type `=` followed by your calculation
3. **Find Files Fast**: Use `.` to search your home directory
4. **Pick Emojis**: Use `:` to search for emojis by name

## Troubleshooting

### Walker doesn't start
```bash
# Check if walker service is running
systemctl --user status walker.service

# Restart walker
systemctl --user restart walker.service
```

### Theme not loading
```bash
# Check theme files exist
ls -la ~/.config/walker/themes/

# Enable hot reload in config:
hotreload_theme = true
```

### Applications not launching
- Check that `uwsm` is running properly
- Verify `launch_prefix = "uwsm app -- "` in config
- Try launching without walker to test the application

## References

- [Walker GitHub](https://github.com/abenz1267/walker)
- [UWSM Documentation](https://github.com/Vladimir-csp/uwsm)
- [Catppuccin Theme](https://github.com/catppuccin/catppuccin)
