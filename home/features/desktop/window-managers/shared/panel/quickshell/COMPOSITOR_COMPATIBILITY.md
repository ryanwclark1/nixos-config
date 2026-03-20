# QuickShell Compositor Compatibility

This document tracks intentional behavior differences between Hyprland and Niri for the panel module at:
`home/features/desktop/window-managers/shared/panel/quickshell`.

## Core Rules

- Route compositor-specific behavior through `src/services/CompositorAdapter.qml`.
- Avoid direct `hyprctl` usage in UI files outside the guard allowlist.
- Hide unsupported UI actions instead of presenting controls that fail at runtime.

## Capability Matrix

The current capability switches are defined in `CompositorAdapter.qml`:

- `supportsWorkspaceListing`: Hyprland, Niri
- `supportsWorkspaceFocus`: Hyprland, Niri
- `supportsWorkspaceOsd`: Hyprland, Niri
- `supportsWindowListing`: Hyprland
- `supportsWorkspaceRename`: Hyprland
- `supportsWorkspaceMove`: Hyprland
- `supportsWorkspaceCloseWindows`: Hyprland
- `supportsScratchpad`: Hyprland
- `supportsDisplayConfig`: Hyprland
- `supportsOverview`: Hyprland
- `supportsHotkeysListing`: Hyprland
- `supportsDispatcherActions`: Hyprland
- `supportsHyprctlSettings`: Hyprland

## Current Niri Behavior

- Workspace strip and workspace OSD use Niri workspace data.
- Workspace focus uses `niri msg action focus-workspace <id>`.
- Launcher mode availability excludes unsupported compositor modes (`window`, `keybinds`) when not supported.
- Hyprland-only settings tabs/actions are filtered through compositor tags or capability checks.
- Privacy screenshare probing uses compositor-aware logic from `CompositorAdapter` (hyprctl-assisted on Hyprland, process-based fallback on Niri/other).
- Wallpaper fallback backend selection is compositor-aware via `CompositorAdapter` (Hyprland hyprpaper fallback only when supported).

## Verification

Run these before merging compositor-related changes:

```bash
make quickshell-checks
make quickshell-test
```

`make quickshell-checks` uses the VM-backed exhaustive path across both
Hyprland and Niri. `make quickshell-test` runs the focused Vitest suite in both
VMs as well. Use `make quickshell-checks-host` or `make quickshell-test-host`
only when you intentionally want the host path.

Equivalent direct scripts:

```bash
./scripts/check-compositor-guards.sh
./scripts/check-compositor-fixtures.sh
./scripts/compositor-smoke.sh
```

## Troubleshooting

- If compositor detection is wrong, inspect:
  - `XDG_CURRENT_DESKTOP`
  - `DESKTOP_SESSION`
  - `HYPRLAND_INSTANCE_SIGNATURE`
  - `NIRI_SOCKET`
- If both Hyprland and Niri markers are present, desktop/session names take precedence.
- If a control is visible but unsupported, add or tighten the corresponding capability gate in `CompositorAdapter.qml`.

## Adding New Compositor-Dependent Features

1. Add capability flag(s) and command/action helper(s) in `CompositorAdapter.qml`.
2. Gate UI visibility and interactions by adapter capabilities (avoid direct compositor checks in UI).
## Keybindings & Shortcuts

- **Global Hotkeys:** Standard QML `Shortcut` elements (e.g., `Meta+S` for Settings) only function when QuickShell has keyboard focus. Since the bar uses `WlrKeyboardFocus.None`, these must be mirrored in the compositor configuration to work globally.
  - **Niri:** Add binds to `config.kdl` that call QuickShell IPC:
    ```kdl
    binds {
        Mod+S { spawn "quickshell" "ipc" "call" "SettingsHub" "toggle"; }
    }
    ```
  - **Hyprland:** Use `bind` in `hyprland.conf`:
    ```conf
    bind = SUPER, S, exec, quickshell ipc call SettingsHub toggle
    ```

- **Focus Policy:** QuickShell surfaces are generally non-interactive or "focus-on-open" to prevent interference with application workflows.
