# Hyprland Scripts

Hyprland-specific scripts only. Shared Wayland and rofi scripts live under
`~/.config/desktop/window-managers/shared/scripts`.

**Source Location**: `home/features/desktop/common/scripts/hyprland/`
**Deployment Location**: `~/.config/desktop/window-managers/hyprland/scripts/`

## Structure

```
scripts/
├── hypr/      # Hyprland compositor helpers (hyprctl, hyprland services)
├── system/    # Hyprland system integration helpers
├── cache/     # Runtime-generated assets (created by scripts)
└── settings/  # Script settings/state (created by scripts)
```

## Notable Scripts

- `hypr/workspace-switcher.sh` - Workspace switcher with previews
- `hypr/hyprland-keybindings.sh` - Keybindings menu (walker-based)
- `hypr/keybindings-menu.sh` - Hyprland binds viewer (walker-based)
- `system/hypr-utils.sh` - Hyprland utility wrapper commands

## Usage

```bash
# Show keybindings menu
$HYPR_SCRIPTS/hypr/hyprland-keybindings.sh
```
