# QuickShell Structure Checklist

Use this checklist before merging panel architecture changes.

- [ ] New closable surfaces are registered through `shell.qml` surface APIs (`toggleSurface/openSurface/closeAllSurfaces`), not ad-hoc booleans.
- [ ] Popup menu placement uses shared anchor helpers in `shell.qml`.
- [ ] Shared state changes live in `services/` (especially `Config.qml`) and are not duplicated across UI modules.
- [ ] New desktop widgets are integrated via `DesktopWidgetRegistry` (built-in or plugin path), not hardcoded in multiple places.
- [ ] Plugin behavior preserves manifest compatibility (`bar-widget` / `desktop-widget`).
- [ ] Existing IPC actions remain backward compatible.
