# QuickShell Structure Checklist

Use this checklist before merging panel architecture changes.

- [ ] New closable surfaces are registered through `shell.qml` surface APIs (`toggleSurface/openSurface/closeAllSurfaces`), not ad-hoc booleans.
- [ ] Popup menu placement uses shared anchor helpers in `shell.qml`.
- [ ] Shared state changes live in `services/` (especially `Config.qml`) and are not duplicated across UI modules.
- [ ] Compositor-specific behavior routes through `services/CompositorAdapter.qml` capabilities, not ad-hoc WM checks.
- [ ] `scripts/check-compositor-guards.sh` passes for QML compositor guardrails.
- [ ] `scripts/compositor-smoke.sh` (or `qs-compositor-smoke-check`) passes in the active compositor session.
- [ ] `scripts/check-launcher-keymap.sh` passes for launcher keyboard behavior guardrails (`Tab`, `Shift+Tab`, and persisted tab behavior settings).
- [ ] `scripts/check-launcher-web-aliases.sh` passes for launcher alias guardrails (normalization, settings wiring, and runtime alias resolution/hints).
- [ ] `scripts/check-launcher-performance.sh` passes for launcher filter/ranking performance guardrails and runtime telemetry fields.
- [ ] `scripts/check-launcher-guardrails.sh` passes (composite launcher guardrail runner).
- [ ] New desktop widgets are integrated via `DesktopWidgetRegistry` (built-in or plugin path), not hardcoded in multiple places.
- [ ] Plugin behavior preserves manifest compatibility (`bar-widget` / `desktop-widget`).
- [ ] Existing IPC actions remain backward compatible.
