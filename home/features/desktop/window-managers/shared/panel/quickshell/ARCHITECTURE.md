# QuickShell Architecture

This document defines the canonical structure for the active panel at:
`home/features/desktop/window-managers/shared/panel/quickshell`.

Compositor-specific behavior notes and capability expectations are documented in
`COMPOSITOR_COMPATIBILITY.md`.

## Mental Model

- `Shell Orchestrator`: top-level surface state, IPC entrypoints, per-screen wiring.
- `Bar`: primary command/status surface.
- `Popup Menus`: bar-anchored contextual popups (audio/network/bluetooth/etc).
- `Centers`: notification center and control center.
- `Launcher + Overview`: app/window search and window overview.
- `OSD`: transient event-driven overlays (volume/brightness/media/workspace).
- `Desktop Widgets`: desktop-layer widgets with edit mode and persistence.
- `Dock`: launcher/task surface.
- `Notifications`: popup notifications + manager.
- `System/Decorative Layers`: lock, toast overlay, corners, borders.
- `Services`: shared state, persistence, and integration logic.

## Dependency Rules

- `shell.qml` owns closable surface orchestration and screen routing.
- Reusable UI in `widgets/` must not directly orchestrate other surfaces.
- `menu/`, `bar/`, `launcher/`, `notifications/`, `widgets/` may depend on `services/`.
- `services/` must not depend on higher-level UI modules.
- Persistent settings shape is owned by `services/Config.qml`.

## Extension Points

- Bar plugins: `PluginService.barPlugins` rendered by the bar.
- Desktop plugins: `PluginService.desktopPlugins` merged into `DesktopWidgetRegistry.widgetCatalog`.
- Plugin manifest contract:
  - required: `id`, `name`, `type`, `main`
  - supported `type`: `bar-widget`, `desktop-widget`

## Invariants

- Only one closable surface is active at a time (`activeSurfaceId` in `shell.qml`).
- Existing IPC compatibility methods remain available while routing through generic surface APIs.
- Popup menus are positioned through shared anchor helpers in `shell.qml`.
- Desktop widgets are stored per monitor in `Config.desktopWidgetsMonitorWidgets`.

## Naming and Placement

- Top-level UI surfaces should be orchestrated in `shell.qml`.
- Reusable leaf widgets belong in `config/widgets/`.
- Shared state and integration logic belongs in `config/services/`.
- New popup/menu surfaces belong in `config/menu/` and should use shared surface IDs.
