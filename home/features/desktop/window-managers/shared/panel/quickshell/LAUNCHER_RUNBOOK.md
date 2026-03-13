# Launcher Reliability Runbook

Use this guide for day-to-day launcher validation and incident triage.

## Quick Commands

- Guardrails only:
  - `scripts/check-launcher-guardrails.sh`
- Benchmarks with thresholds and parity checks:
  - `scripts/check-launcher-benchmarks.sh`
- Full launcher smoke gate:
  - `scripts/check-launcher-smoke.sh`

## Benchmark Baselines

- Baselines file:
  - `scripts/launcher-benchmark-baselines.json`
- To update baselines, run benchmarks on a stable machine/load profile and edit:
  - `max_optimized_ms`
  - `tolerance_pct`

## Runtime Metrics Interpretation

Enable `Show Runtime Metrics` in Launcher settings.

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

## Incident Triage Sequence

1. Run `scripts/check-launcher-smoke.sh`.
2. If benchmark gate fails, inspect `scripts/launcher-benchmark-baselines.json` versus current host load.
3. In a live session, open launcher runtime metrics and verify:
   - backend is expected (`fd` preferred),
   - resolve cost is low/stable,
   - files cache hit rate is non-zero during repeated queries.
4. Trigger `Re-detect Files Backend`; confirm backend/resolve metrics update.
