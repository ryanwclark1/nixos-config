# Launcher Reliability Runbook

Use this guide for day-to-day launcher validation and incident triage.

For implementation planning beyond this runbook, see `NEXT_STEPS.md`.

## Quick Commands

- Guardrails only:
  - `scripts/check-launcher-guardrails.sh`
- Tab/Shift+Tab behavior matrix:
  - `scripts/check-launcher-tab-matrix.sh`
- Responsive/runtime smoke for launcher surface:
  - `scripts/check-launcher-responsive.sh`
  - preferred repo-checkout path: `scripts/check-launcher-responsive.sh --repo-shell`
- Live launcher IPC health and status payload contract:
  - `scripts/check-launcher-ipc-health.sh`
  - preferred repo-checkout path: `scripts/check-launcher-ipc-health.sh --repo-shell`
- Benchmarks with thresholds and parity checks:
  - `scripts/check-launcher-benchmarks.sh`
- Full launcher smoke gate:
  - `scripts/check-launcher-smoke.sh`
  - preferred repo-checkout path: `scripts/check-launcher-smoke.sh --repo-shell`
- CI-safe launcher smoke gate:
  - `scripts/check-launcher-smoke.sh --ci`
  - If no live QuickShell launcher instance is reachable, smoke falls back to static launcher probes, skips live category/`Esc` diagnostics, and still runs benchmarks.
- Launcher visual capture artifact:
  - `scripts/capture-launcher-viewport.sh --mode drun --state home`
- Launcher visual capture matrix:
  - `scripts/capture-launcher-matrix.sh`

Live launcher scripts auto-select a QuickShell instance in this order:
1. launched from this repo’s `src/shell.qml` and exposing both `drunCategoryState` and `escapeActionState`
2. launched from this repo’s `src/shell.qml`
3. exposing `drunCategoryState`
4. exposing `escapeActionState`
5. any launcher-capable instance

`--repo-shell` is now the preferred validation path when you need to test the repo checkout directly. It launches this tree’s `src/shell.qml`, keeps the probe bound to that PID, and avoids stale installed-session QML.

## Current Verified Baseline

- `scripts/check-launcher-responsive.sh --repo-shell`
  - summary: `14 pass, 1 warn, 0 fail`
  - the remaining warning is acceptable when no non-`All` drun category option is available in the fresh repo-shell instance
- `scripts/check-launcher-ipc-health.sh --repo-shell`
  - emits `{"ok":true,...,"errors":[]}`
- `scripts/check-launcher-smoke.sh --repo-shell`
  - passes end to end, including guardrails, live responsive/IPC probes, and benchmarks

Recent runtime fix that materially changed this baseline:
- `Launcher` IPC methods that return JSON diagnostics now declare `: string`, so `drunCategoryState`, `escapeActionState`, `diagnosticSetSearchText`, `diagnosticSetDrunCategoryFilter`, and `invokeEscapeAction` no longer get coerced to `void` by Qt.

## Benchmark Baselines

- Baselines file:
  - `scripts/launcher-benchmark-baselines.json`
- To update baselines, run benchmarks on a stable machine/load profile and edit:
  - `max_optimized_ms`
  - `tolerance_pct`

## Baseline Governance

- Update baselines only after a deliberate launcher performance change.
- Record benchmark evidence for all three scripts before and after updates:
  - `benchmark-launcher-filter.js`
  - `benchmark-launcher-home.js`
  - `benchmark-launcher-files-shaping.js`
- Do not relax `tolerance_pct` to hide regressions; prefer improving implementation first.
- Keep baseline updates and performance-related code changes in the same reviewable change set.

## Runtime Metrics Interpretation

Enable `Show Runtime Metrics` in Launcher settings.

`Category/Keywords Weight` currently affects app ranking in `drun` mode only.

In `drun` home, category quick-filter shortcuts are:
- `Alt+Left/Alt+Right` or `Alt+PageUp/Alt+PageDown`: cycle categories
- `Alt+Home` / `Alt+End`: jump to the first/last category
- `Ctrl+Tab` / `Ctrl+Shift+Tab`: cycle next/previous category without changing launcher mode
- `Alt+1..9`: jump to category slot
- `Alt+0` / `Alt+Backspace`: reset to `All`

Use `App Category Filters` in Launcher settings to enable/disable these chips and shortcuts.

Result-list navigation shortcuts:
- `Up` / `Down`: move one result
- `Ctrl+P` / `Ctrl+N`: move to previous/next result
- `PageUp` / `PageDown`: jump by a visible page of results
- `Home` / `End`: jump to first/last result

Query shortcuts:
- `Ctrl+L` / `Ctrl+U`: clear the current launcher query and keep focus in the search field
- `Esc`: cancel confirm, otherwise reset the current query or active app-category filter before closing the launcher on the next press

## Visual Capture

Use the launcher capture script when you need a review artifact for the upgraded launcher UI.

- drun home:
  - `scripts/capture-launcher-viewport.sh --mode drun --state home`
- drun query results:
  - `scripts/capture-launcher-viewport.sh --mode drun --state query --query firefox`
- drun category state:
  - `scripts/capture-launcher-viewport.sh --mode drun --state category`
- files empty state:
  - `scripts/capture-launcher-viewport.sh --mode files --state empty`
- system mode:
  - `scripts/capture-launcher-viewport.sh --mode system --state home`

Default output goes to `/tmp/launcher-<mode>-<state>.png`.

Use the launcher matrix script when you want the core review set in one pass.

- core launcher matrix:
  - `scripts/capture-launcher-matrix.sh`
- packaged helper:
  - `qs-launcher-capture-matrix`

The launcher matrix writes an `index.html` gallery beside the PNG artifacts for quick review.

- Core line:
  - `opens`, `cache`, `failures`, `filter avg/last`
- Files backend line additions:
  - `backend`: currently active backend (`fd`, `find`, `none`, `auto`)
  - `fd/find`: count of files loads executed by each backend
  - `fd avg/last ms`, `find avg/last ms`: per-backend latency quality
  - `resolve avg/last ms`: backend auto-detection probe cost
  - `cache h/m (p%)`: files mode cache hit/miss effectiveness

## Manual Recovery Actions

- Re-detect files backend:
  - Launcher settings -> `Re-detect Files Backend`
  - or `quickshell ipc call Launcher redetectFilesBackend`
- Reset launcher metrics:
  - Launcher settings -> `Reset Runtime Metrics`
  - or `quickshell ipc call Launcher clearMetrics`
- Reset launcher diagnostics (metrics + files backend state/cache):
  - Launcher settings -> `Launcher Diagnostic Reset`
  - or `quickshell ipc call Launcher diagnosticReset`
- Inspect files backend status payload:
  - `quickshell ipc call Launcher filesBackendStatus`
- Inspect drun category-chip state payload (enabled/visible/active badge counts):
  - `quickshell ipc call Launcher drunCategoryState`
- Inspect `Esc` action state payload (cancel/reset/close branch selection):
  - `quickshell ipc call Launcher escapeActionState`

## Incident Triage Sequence

1. Run `scripts/check-launcher-smoke.sh --repo-shell`.
2. If benchmark gate fails, inspect `scripts/launcher-benchmark-baselines.json` versus current host load.
3. If IPC health fails, run `scripts/check-launcher-ipc-health.sh --repo-shell` first, then `scripts/check-launcher-ipc-health.sh --id <instance-id>` if you need to compare against an installed session, and inspect the emitted JSON `errors` list.
   - Live checks now attempt `Shell.reloadConfig` automatically before warning on missing `drunCategoryState` or `escapeActionState` diagnostics.
   - If `drunCategoryState` or `escapeActionState` is missing, or returns empty/non-JSON payload after reload while static checks pass, confirm the repo checkout still has typed `: string` launcher IPC diagnostics before treating it as a session-staleness problem.
4. In a live session, open launcher runtime metrics and verify:
   - backend is expected (`fd` preferred),
   - resolve cost is low/stable,
   - files cache hit rate is non-zero during repeated queries.
5. Trigger `Re-detect Files Backend`; confirm backend/resolve metrics update.
