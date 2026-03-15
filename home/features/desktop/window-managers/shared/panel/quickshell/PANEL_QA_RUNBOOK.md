# Panel QA Runbook

Use this runbook after changes to the shared QuickShell panel runtime, popup surfaces, multibar behavior, or responsive settings flows.

Related docs:

- settings-specific workflow: `SETTINGS_RESPONSIVE_RUNBOOK.md`
- settings responsive history and findings: `SETTINGS_RESPONSIVE_CLOSEOUT.md`
- plugin-specific local workflow: `config/plugins/README.md`

## Canonical Commands

Packaged command entrypoints:

- automated gate: config and migration contracts:
  - `qs-panel-config-contracts`
- automated gate: full runtime verification:
  - `qs-panel-runtime-verify`
- manual walkthrough: preview sequence:
  - `qs-panel-preview`
- review artifact capture: full screenshot artifact set:
  - `qs-panel-capture-matrix`

Focused commands:

- automated gate: settings runtime smoke:
  - `qs-panel-runtime-verify --skip-surfaces --skip-multibar`
- automated gate: surface runtime smoke:
  - `qs-panel-runtime-verify --skip-settings --skip-multibar`
- automated gate: synthetic multibar smoke:
  - `qs-panel-runtime-verify --skip-settings --skip-surfaces`
- manual walkthrough: settings-only preview:
  - `qs-panel-preview --skip-surfaces`
- manual walkthrough: surfaces-only preview:
  - `qs-panel-preview --skip-settings`
- review artifact capture: settings screenshot matrix:
  - `qs-settings-capture-matrix --preset portrait`
- review artifact capture: surface screenshot matrix:
  - `qs-surface-capture-matrix --crop surface`

Repo-checkout workflow:

- automated gate against the repo shell:
  - `qs-panel-runtime-verify --repo-shell`
- manual walkthrough against the repo shell:
  - `qs-panel-preview --repo-shell`
- review artifact capture against the repo shell:
  - `qs-panel-capture-matrix --repo-shell --settings-preset portrait --surface-crop surface`

Script equivalents remain available under `scripts/` when you want to run them from the repo checkout directly.

Command roles:

- `qs-panel-config-contracts` and `qs-panel-runtime-verify` are automated gates.
- `qs-panel-preview` is a live-session walkthrough.
- `qs-panel-capture-matrix` produces review artifacts.

If more than one QuickShell instance is running:

- `qs-panel-runtime-verify --id <instance-id>`
- `qs-panel-preview --id <instance-id>`
- `qs-panel-capture-matrix --id <instance-id> --settings-preset portrait --surface-crop surface`

If the managed `quickshell.service` is stale, broken, or intentionally stopped:

- prefer the `--repo-shell` path instead of guessing a live instance id
- this temporarily stops `quickshell.service`, launches the repo checkout as the live shell, runs the requested QA flow, then attempts to restore the service afterward
- use this path when validating repo-only changes before a Home Manager rebuild has been applied

## What Each Command Covers

`qs-panel-runtime-verify`

1. Runs headless-safe panel config contract checks.
2. Runs settings responsive smoke against the live shell.
3. Runs popup/panel surface smoke against the live shell.
4. Runs the synthetic multibar shell matrix and bar-management harnesses.

This is the required runtime gate after panel changes.
`--repo-shell` makes this gate self-contained by launching the repo checkout as the live shell first.

The synthetic multibar phase uses temporary QML harnesses that mirror the real panel config tree so `BarTab` and `BarWidgetsTab` resolve the same sibling imports they use in the shipped settings UI.
The live settings and surface phases use `PASS`, `WARN`, and `FAIL` outcomes only; the `[SKIP]` classification is specific to the headless multibar phase.

`qs-panel-config-contracts`

1. Verifies default stat-widget settings.
2. Verifies legacy `systemMonitor` configs expand to CPU + Memory widgets.
3. Verifies new default bar composition uses separated stat widgets.
4. Verifies sparse CPU / Memory / GPU widget settings inherit missing defaults during normalization.

This is the fastest no-session gate for stat-widget and config-migration changes.

`qs-panel-preview`

1. Walks the high-risk settings tabs.
2. Walks the high-risk popup/panel surfaces.
3. Gives a tester a repeatable live-session sequence for visual QA.

This is for manual inspection, not pass/fail gating.
It does not emit `PASS`, `WARN`, `FAIL`, or `[SKIP]` results; use it to drive visual review after the automated checks.
`--repo-shell` is the preferred option when you need to preview repo-only changes that are not yet active in the managed shell.

`qs-panel-capture-matrix`

1. Captures portrait settings screenshots for the high-risk tabs.
2. Captures a deeper portrait settings pass by default to expose lower-scroll sections in dense tabs.
3. Captures tight popup/panel surface crops for the high-risk popup/panel surfaces.
4. Uses a dedicated empty workspace by default so the capture run does not reuse the current working workspace.
5. Waits for the requested workspace to become active before capturing instead of relying on a fixed settle sleep.
6. Restores the original workspace after the run completes.
7. Writes a review artifact set under a single output directory.
8. Generates an `index.html` gallery for quick inspection.

This is for review and bug triage, not runtime health.
It does not emit `PASS`, `WARN`, `FAIL`, or `[SKIP]` results; use the generated artifacts for manual visual review.
`--repo-shell` is the preferred option when the installed shell does not match the repo checkout or the managed service is unhealthy.

## Recommended QA Sequence

1. Run the automated gate: `qs-panel-runtime-verify`.
2. Run the manual walkthrough: `qs-panel-preview` on the live session.
3. Generate review artifacts: `qs-panel-capture-matrix --settings-preset portrait --surface-crop surface`.
   Use `--workspace current` only if you intentionally want captures from the currently active workspace.
4. Open the generated `index.html` gallery and record only concrete defects.
5. Re-run the smallest relevant subset after each fix.

If the managed shell does not reflect the repo checkout yet:

1. Run `qs-panel-runtime-verify --repo-shell`.
2. Run `qs-panel-preview --repo-shell`.
3. Run `qs-panel-capture-matrix --repo-shell --settings-preset portrait --surface-crop surface`.

## Manual QA Matrix

Validate these layouts:

- large landscape
- standard laptop landscape
- narrow display
- portrait display
- multi-monitor with mixed bar positions
- dock sharing an edge with a bar on only some displays

Validate these behaviors:

- popup menus stay inside usable bounds
- Notification Center and Control Center follow the intended edge
- top and bottom bars center popups correctly around triggers
- left and right bars keep popups clear of reserved edges
- compact settings tabs avoid horizontal clipping
- bar management and bar-widget management remain usable in compact mode
- dock coexistence does not force surfaces off-screen
- CPU / Memory / GPU widgets remain independently addable and configurable
- compact and auto stat-widget modes do not widen left/right bars unexpectedly

Environment note:

- In headless or offscreen environments, synthetic multibar smoke can report `[SKIP]` results when `PanelWindow` backends are unavailable.
- Treat those skips as environment limits, not widget regressions.
- The headless harness now strips inherited `WAYLAND_DISPLAY` and `DISPLAY` values, so skip logs should reduce to the actual backend limitation instead of mixed session-environment warnings.
- Temporary bar-management harnesses should now fail only for real QML/runtime issues or the expected `No PanelWindow backend loaded` condition, not malformed local import paths.
- A healthy headless run can therefore end with a summary like `0 pass, 0 warn, 6 skip, 0 fail`.
- Use `qs-panel-config-contracts` for the no-session contract gate and reserve multibar smoke pass/fail expectations for real graphical sessions.
- Current surface-capture automation prefers `--surface-crop surface`; recent matrix runs produced tight artifacts such as `networkMenu 412x576`, `audioMenu 396x584`, `weatherMenu 516x624`, `dateTimeMenu 576x584`, `notifCenter 401x1701`, and `controlCenter 401x1701`.
- The remaining gap is manual visual QA of placement/interaction, not surface-instance discovery or screenshot cropping.

## Triage Format

Record issues in this format:

- screen shape: wide, laptop, narrow, portrait, or multi-monitor
- area: settings, popup surface, panel surface, or multibar runtime
- exact target: tab id or surface id
- trigger edge: top, bottom, left, or right when relevant
- defect: clipping, bad anchor, awkward spacing, or broken interaction
- severity: blocking, awkward, or cosmetic

## Acceptance Criteria

- `qs-panel-runtime-verify` passes.
- No parser/runtime failures or new binding loops are introduced.
- High-risk settings tabs and popup surfaces are visually reviewable via `qs-panel-capture-matrix`.
- Manual QA confirms usable placement on top, bottom, left, and right bars.
- Multi-monitor and dock/bar coexistence cases remain usable.
