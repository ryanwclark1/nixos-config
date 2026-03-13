# QuickShell Structure Checklist

Use this checklist before merging panel architecture changes.

- [ ] New closable surfaces are registered through `shell.qml` surface APIs (`toggleSurface/openSurface/closeAllSurfaces`), not ad-hoc booleans.
- [ ] Popup menu placement uses shared anchor helpers in `shell.qml`.
- [ ] Shared state changes live in `services/` (especially `Config.qml`) and are not duplicated across UI modules.
- [ ] Compositor-specific behavior routes through `services/CompositorAdapter.qml` capabilities, not ad-hoc WM checks.
- [ ] `scripts/check-compositor-guards.sh` passes for QML compositor guardrails.
- [ ] `scripts/check-compositor-fixtures.sh` passes for known Niri payload shapes (array and object forms).
- [ ] `scripts/compositor-smoke.sh` (or `qs-compositor-smoke-check`) passes in the active compositor session.
- [x] `scripts/check-launcher-keymap.sh` passes for launcher keyboard behavior guardrails (`Tab`, `Shift+Tab`, and persisted tab behavior settings).
- [x] `scripts/check-launcher-web-aliases.sh` passes for launcher alias guardrails (normalization, settings wiring, and runtime alias resolution/hints).
- [x] `scripts/check-launcher-performance.sh` passes for launcher filter/ranking performance guardrails and runtime telemetry fields.
- [x] `scripts/check-launcher-guardrails.sh` passes (composite launcher guardrail runner).
- [x] `scripts/check-launcher-benchmarks.sh` passes (threshold + parity gate for launcher benchmarks).
- [x] `scripts/check-launcher-smoke.sh` passes (guardrails + benchmarks in one command).
- [ ] `scripts/check-settings-responsive.sh` passes after changes to `SettingsHub`, shared settings components, or dense settings tabs.
- [x] `node scripts/benchmark-launcher-filter.js --items=30000 --runs=40` is sampled for performance-sensitive launcher ranking changes.
- [x] `node scripts/benchmark-launcher-home.js --apps=30000 --history=500 --runs=60` is sampled after changes to drun home/recent/suggestion composition.
- [x] `node scripts/benchmark-launcher-files-shaping.js --lines=120000 --runs=25` is sampled after files-result parsing/path-shaping changes.
- [ ] Manual settings QA is completed using `SETTINGS_RESPONSIVE_RUNBOOK.md` on wide, laptop, and narrow/portrait layouts when responsive settings surfaces change.
- [ ] New desktop widgets are integrated via `DesktopWidgetRegistry` (built-in or plugin path), not hardcoded in multiple places.
- [ ] Plugin behavior preserves manifest compatibility (`bar-widget` / `desktop-widget`).
- [ ] Existing IPC actions remain backward compatible.
