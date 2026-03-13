# Launcher Reliability Runbook

Use this guide for day-to-day launcher validation and incident triage.

## Quick Commands

- Guardrails only:
  - `scripts/check-launcher-guardrails.sh`
- Tab/Shift+Tab behavior matrix:
  - `scripts/check-launcher-tab-matrix.sh`
- Responsive/runtime smoke for launcher surface:
  - `scripts/check-launcher-responsive.sh`
- Live launcher IPC health and status payload contract:
  - `scripts/check-launcher-ipc-health.sh`
- Benchmarks with thresholds and parity checks:
  - `scripts/check-launcher-benchmarks.sh`
- Full launcher smoke gate:
  - `scripts/check-launcher-smoke.sh`
- CI-safe launcher smoke gate:
  - `scripts/check-launcher-smoke.sh --ci`

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
- `Alt+Left/Alt+Right`: cycle categories
- `Alt+1..9`: jump to category slot
- `Alt+0`: reset to `All`

Use `App Category Filters` in Launcher settings to enable/disable these chips and shortcuts.

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

## Incident Triage Sequence

1. Run `scripts/check-launcher-smoke.sh`.
2. If benchmark gate fails, inspect `scripts/launcher-benchmark-baselines.json` versus current host load.
3. If IPC health fails, run `scripts/check-launcher-ipc-health.sh --id <instance-id>` and inspect the emitted JSON `errors` list.
   - If `drunCategoryState` is missing in a live instance but static checks pass, restart/reload QuickShell for that session and rerun smoke.
4. In a live session, open launcher runtime metrics and verify:
   - backend is expected (`fd` preferred),
   - resolve cost is low/stable,
   - files cache hit rate is non-zero during repeated queries.
5. Trigger `Re-detect Files Backend`; confirm backend/resolve metrics update.
