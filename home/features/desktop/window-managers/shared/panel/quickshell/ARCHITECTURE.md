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
- `Shared UI`: reusable UI primitives, controls, and feedback helpers.

## Dependency Rules

- `src/shell.qml` and `src/app/ShellRoot.qml` own closable surface orchestration and screen routing.
- Feature roots in `src/features/` own their surfaces, local components, and registries.
- Reusable UI lives in `src/shared/` and must not directly orchestrate other surfaces.
- `src/widgets/qmldir` is a compatibility facade only; new runtime ownership does not belong there.
- `menu/`, `bar/`, `launcher/`, `notifications/`, `shared/`, and `shell/` may depend on `services/`.
- `services/` must not depend on higher-level UI modules.
- Persistent settings shape is owned by `services/Config.qml`.

## Extension Points

- Bar plugins: `PluginService.barPlugins` rendered by the bar.
- Desktop plugins: `PluginService.desktopPlugins` merged into `DesktopWidgetRegistry.widgetCatalog`.
- Plugin manifest contract:
  - required: `id`, `name`, `description`, `author`, `version`, `type`, `permissions`, `entryPoints`
  - supported `type`: `bar-widget`, `desktop-widget`, `launcher-provider`, `daemon`, `multi`

## Invariants

- Only one closable surface is active at a time (`activeSurfaceId` in `src/app/ShellRoot.qml`).
- Existing IPC compatibility methods remain available while routing through generic surface APIs.
- Popup menus are positioned through shared anchor helpers in `src/app/ShellRoot.qml`.
- Desktop widgets are stored per monitor in `Config.desktopWidgetsMonitorWidgets`.

## Naming and Placement

- Top-level UI surfaces should be orchestrated in `src/app/ShellRoot.qml`.
- Feature-owned surfaces and components belong in `src/features/<feature>/`.
- Reusable leaf widgets and generic controls belong in `src/shared/`.
- Shell-only decoration surfaces belong in `src/shell/`.
- Shared state and integration logic belongs in `src/services/`.
- `src/menu/` and `src/widgets/` exist for backward-compatible module resolution and should stay thin.
