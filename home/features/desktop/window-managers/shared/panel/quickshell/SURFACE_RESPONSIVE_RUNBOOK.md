# Surface Responsive Runbook

Use this runbook after changes to popup menus, panel surfaces, or shared shell surface orchestration.

## Quick Commands

- Runtime popup/panel smoke check against the live QuickShell instance:
  - `scripts/check-surface-responsive.sh`
- Runtime popup/panel smoke check against the repo shell:
  - `scripts/check-panel-runtime.sh --repo-shell --skip-settings --skip-multibar`
- Manual popup/panel preview walk:
  - `scripts/preview-surface-responsive.sh`
- Manual popup/panel preview against the repo shell:
  - `scripts/preview-panel-qa.sh --repo-shell --skip-settings`
- Focused surface screenshot capture:
  - `scripts/capture-surface-viewport.sh --surface networkMenu`
- High-risk surface screenshot matrix:
  - `scripts/capture-surface-matrix.sh --crop surface`
- Combined settings + surface QA capture set:
  - `scripts/capture-panel-matrix.sh --settings-preset portrait --surface-crop surface`
  - uses a dedicated empty workspace by default
  - pass `--workspace current` only when you explicitly want live-workspace captures
- Combined settings + surface QA capture set against the repo shell:
  - `scripts/capture-panel-matrix.sh --repo-shell --settings-preset portrait --surface-crop surface`
- If more than one QuickShell instance is running:
  - `scripts/check-surface-responsive.sh --id <instance-id>`
  - `scripts/preview-surface-responsive.sh --id <instance-id>`
- If the managed `quickshell.service` is stale, broken, or not yet rebuilt from the repo:
  - prefer `--repo-shell` on the panel-level wrappers instead of guessing an instance id
  - this temporarily stops the managed service, launches the repo checkout as the live shell, runs QA, then attempts to restore the service
- Synthetic multi-bar shell matrix and management harnesses:
  - `scripts/check-multibar-smoke.sh`

## What The Smoke Script Covers

The smoke script:

1. Locates a live QuickShell instance.
2. Calls `Shell.reloadConfig()`.
3. Opens each closable popup or panel surface through Shell IPC.
4. Closes the surface stack between openings.
5. Scans new QuickShell runtime log output for warnings/errors.

Covered surfaces:

- `notifCenter`
- `controlCenter`
- `networkMenu`
- `audioMenu`
- `bluetoothMenu`
- `printerMenu`
- `privacyMenu`
- `clipboardMenu`
- `recordingMenu`
- `musicMenu`
- `batteryMenu`
- `weatherMenu`
- `dateTimeMenu`
- `systemStatsMenu`
- `powerMenu`
- `notepad`
- `colorPicker`
- `displayConfig`
- `cavaPopup`

This is a runtime creation-path guardrail, not a replacement for visual QA.
If the installed shell does not reflect the repo checkout yet, use `scripts/check-panel-runtime.sh --repo-shell --skip-settings --skip-multibar` instead.

## What The Preview Script Covers

The preview script:

1. Reloads the live shell.
2. Opens each surface in sequence.
3. Leaves each surface visible for a configurable delay.
4. Closes before moving to the next surface.

Recommended usage:

- default delay:
  - `scripts/preview-surface-responsive.sh`
- slower walkthrough:
  - `scripts/preview-surface-responsive.sh --delay 3`
- repo-shell walkthrough:
  - `scripts/preview-panel-qa.sh --repo-shell --skip-settings`

## Screenshot Capture

Use the capture scripts when you need repeatable screenshots from the live shell on the focused monitor.

Examples:

- tight surface crop for one surface:
  - `scripts/capture-surface-viewport.sh --surface weatherMenu --crop surface`
- usable-area crop for one surface:
  - `scripts/capture-surface-viewport.sh --surface controlCenter --crop usable`
- full focused monitor capture for one surface:
  - `scripts/capture-surface-viewport.sh --surface weatherMenu`
- write to a specific file:
  - `scripts/capture-surface-viewport.sh --surface networkMenu --output /tmp/network-menu.png`

For a small high-risk batch:

- tight surface crop:
  - `scripts/capture-surface-matrix.sh --crop surface`
- usable-area crop:
  - `scripts/capture-surface-matrix.sh --crop usable`

For a combined artifact set:

- portrait settings + surface-cropped surfaces:
  - `scripts/capture-panel-matrix.sh --settings-preset portrait --surface-crop surface`
- settings only:
  - `scripts/capture-panel-matrix.sh --skip-surfaces`
- surfaces only:
  - `scripts/capture-panel-matrix.sh --skip-settings --surface-crop surface`
- repo-shell combined capture:
  - `scripts/capture-panel-matrix.sh --repo-shell --settings-preset portrait --surface-crop surface`

This is for visual inspection only. It complements, but does not replace, the live smoke checks.

Recent automated captures from the live shell produced:

- `networkMenu`: `412x576`
- `audioMenu`: `396x584`
- `weatherMenu`: `516x624`
- `dateTimeMenu`: `576x584`
- `notifCenter`: `401x1701`
- `controlCenter`: `401x1701`

That means the capture path is now proving tight popup/panel crops reliably. The remaining work is manual review of placement and interaction across layouts.

## Manual Visual QA Matrix

Validate the surface stack in these layouts:

- large landscape
- standard laptop landscape
- narrow display
- portrait display
- multi-monitor with mixed bar positions

For each layout, verify:

- popup menus stay inside usable bounds
- Notification Center and Control Center open from the intended edge
- top/bottom bars center their popups correctly around the trigger
- left/right bars keep popups clear of reserved edges
- dock coexistence does not cause surfaces to appear off-screen
- modal surfaces remain inside the visible usable area

## High-Risk Cases

Prioritize these cases during manual QA:

1. left bar + right dock
2. right bar + bottom bar
3. dock sharing the same edge as a bar on only some displays
4. narrow/portrait monitor with `DateTimeMenu`, `WeatherMenu`, `NetworkMenu`, and `AudioMenu`
5. `notifCenter` and `controlCenter` opened from different bar edges

## Triage Format

Record remaining issues in this format:

- screen shape: wide, laptop, narrow, portrait, or multi-monitor
- surface: exact surface id or menu name
- trigger edge: top, bottom, left, or right
- defect: clipping, bad anchor, awkward spacing, or broken interaction
- severity: blocking, awkward, or cosmetic

## Acceptance Criteria

- All listed surfaces open and close through Shell IPC without runtime warnings.
- No surface appears outside the usable screen area during manual QA.
- Trigger-follow behavior remains coherent for top, bottom, left, and right bars.
- Multi-monitor and dock/bar coexistence cases remain usable.
