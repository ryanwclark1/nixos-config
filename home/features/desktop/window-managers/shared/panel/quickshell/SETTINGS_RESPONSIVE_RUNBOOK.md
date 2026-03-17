# Settings Responsive Runbook

Use this runbook after changes to the settings hub shell, shared settings primitives, or dense settings tabs.

Reference:

- historical closeout: `SETTINGS_RESPONSIVE_CLOSEOUT.md`

## Quick Commands

- Automated gate: headless config/migration contract check for Bar Widgets stat settings:
  - `scripts/check-panel-config-contracts.sh`
- Automated gate: static + runtime guardrails:
  - `scripts/check-settings-guardrails.sh`
- Automated gate: settings-focused QA stack:
  - `scripts/check-settings-qa.sh --skip-switch`
- Automated gate: widget picker search regression:
  - `scripts/check-widget-picker-search.sh`
- Automated gate: runtime smoke check against the live QuickShell instance:
  - `scripts/check-settings-responsive.sh`
- Automated gate: runtime smoke check against the repo shell:
  - `scripts/check-panel-runtime.sh --repo-shell --skip-surfaces --skip-multibar`
- Manual walkthrough: tab preview for visual QA:
  - `scripts/preview-settings-responsive.sh`
- Manual walkthrough against the repo shell:
  - `scripts/preview-panel-qa.sh --repo-shell --skip-surfaces`
- Review artifact capture: simulated viewport screenshot:
  - `scripts/capture-settings-viewport.sh --width 430 --height 932 --tab wallpaper`
- Review artifact capture: simulated lower-fold screenshot:
  - `scripts/capture-settings-viewport.sh --width 430 --height 932 --tab wallpaper --scroll-y 900`
- Review artifact capture: batch viewport matrix:
  - `scripts/capture-settings-matrix.sh --preset portrait`
- Review artifact capture against the repo shell:
  - `scripts/capture-panel-matrix.sh --repo-shell --skip-surfaces --settings-preset portrait`
- Review artifact capture: batch lower-fold viewport matrix:
  - `scripts/capture-settings-matrix.sh --preset portrait --scroll-y 900 --output-dir /tmp/settings-matrix-portrait-lower`
- If more than one QuickShell instance is running:
  - `scripts/check-settings-guardrails.sh --id <instance-id>`
  - `scripts/check-settings-responsive.sh --id <instance-id>`
  - `scripts/preview-settings-responsive.sh --id <instance-id>`
  - `scripts/capture-settings-viewport.sh --id <instance-id> --width 430 --height 932 --tab wallpaper`
  - `scripts/capture-settings-matrix.sh --id <instance-id> --preset portrait`
- If the managed `quickshell.service` is stale, broken, or not yet rebuilt from the repo:
  - prefer `--repo-shell` on the panel-level wrappers instead of guessing an instance id
  - this temporarily stops the managed service, launches the repo checkout as the live shell, runs QA, then attempts to restore the service
- Static parse validation for touched QML:
  - `qmlformat -n config/menu/SettingsHub.qml config/menu/settings/*.qml config/menu/settings/tabs/*.qml`

Command roles:

- `check-settings-responsive.sh` is the live-session runtime gate.
- `check-settings-qa.sh --skip-switch` is the settings-specific integrated regression stack.
- `check-widget-picker-search.sh` is the headless add-widget catalog/search regression check.
- `preview-settings-responsive.sh` is a manual walkthrough.
- `capture-settings-viewport.sh` and `capture-settings-matrix.sh` produce review artifacts.

Capture note:

- Settings viewport captures use padded modal framing so the full left sidebar remains visible in portrait review artifacts.
- If the ambient shell is unstable during capture, prefer:
  - `scripts/capture-panel-matrix.sh --repo-shell --skip-surfaces --settings-preset portrait`

## What The Smoke Script Covers

The smoke script:

1. Locates a live QuickShell instance.
2. Calls `Shell.reloadConfig()`.
3. Opens `SettingsHub`.
4. Cycles the highest-risk tabs:
   - `launcher`
   - `launcher-search`
   - `launcher-web`
   - `launcher-modes`
   - `launcher-runtime`
   - `wallpaper`
   - `bar-widgets`
   - `bars`
   - `system`
   - `plugins`
   - `theme`
   - `hotkeys`
   - `time-weather`
5. Scans new QuickShell runtime log output for warnings/errors.

This is a runtime guardrail, not a replacement for visual QA.
If the installed shell does not reflect the repo checkout yet, use `scripts/check-panel-runtime.sh --repo-shell --skip-surfaces --skip-multibar` instead.

Unlike the headless multibar smoke in the panel QA flow, this live-session check uses only `PASS`, `WARN`, and `FAIL` outcomes. It does not emit `[SKIP]` results.

Current verified repo-shell baseline:

- `scripts/check-panel-runtime.sh --repo-shell --skip-surfaces --skip-multibar`
- summary: `12 pass, 0 warn, 0 fail`
- covered tabs: `wallpaper`, `bar-widgets`, `bars`, `system`, `plugins`, `theme`, `hotkeys`, `time-weather`
- recent runtime fixes that made this clean again:
  - deferred `SettingsHub` tab-open persistence now guards initialization,
  - `CommandPoll` no longer emits startup `triggerPoll` type errors,
  - missing shared support widgets/imports uncovered during repo-shell verification were restored.

## What The Preview Script Covers

The preview script:

1. Reloads the live shell.
2. Opens `SettingsHub`.
3. Walks the high-risk tabs in order with a configurable delay.
4. Gives a tester a repeatable sequence for wide, laptop, and narrow/portrait checks.

Recommended usage:

- default delay:
  - `scripts/preview-settings-responsive.sh`
- slower walkthrough:
  - `scripts/preview-settings-responsive.sh --delay 4`
- repo-shell walkthrough:
  - `scripts/preview-panel-qa.sh --repo-shell --skip-surfaces`

## Simulated Compact QA

Use the viewport capture script when you need repeatable narrow or portrait screenshots from a wide desktop session.
If the installed shell is stale or unhealthy, prefer the repo-shell artifact path:
- `scripts/capture-panel-matrix.sh --repo-shell --skip-surfaces --settings-preset portrait`

For Bar Widgets stat-setting changes, run `scripts/check-panel-config-contracts.sh` first so default/migration regressions are caught before live-session layout review.
For add-widget picker changes, run `scripts/check-widget-picker-search.sh` or the broader `scripts/check-settings-qa.sh --skip-switch` stack before manual review.
Recommended order: run the runtime gate first, then the manual preview walkthrough, then generate capture artifacts if you need repeatable screenshots for review or bug triage.
If you are validating repo-only changes before a Home Manager rebuild, use the repo-shell variants of those steps instead.

Examples:

- portrait phone-like width:
  - `scripts/capture-settings-viewport.sh --width 430 --height 932 --tab wallpaper`
- portrait tablet:
  - `scripts/capture-settings-viewport.sh --width 820 --height 1180 --tab system`
- compact tab check saved to a specific file:
  - `scripts/capture-settings-viewport.sh --width 430 --height 932 --tab plugins --output /tmp/plugins-portrait.png`
- compact lower-section check:
  - `scripts/capture-settings-viewport.sh --width 430 --height 932 --tab bar-widgets --scroll-y 900 --output /tmp/bar-widgets-portrait-lower.png`

Use this to generate review artifacts for manual visual inspection only. It does not emit `PASS`, `WARN`, `FAIL`, or `[SKIP]` results, and it does not replace the live runtime smoke gate.

For a full preset sweep of the highest-risk tabs:

- portrait matrix:
  - `scripts/capture-settings-matrix.sh --preset portrait`
- laptop matrix:
  - `scripts/capture-settings-matrix.sh --preset laptop`
- portrait lower-fold matrix:
  - `scripts/capture-settings-matrix.sh --preset portrait --scroll-y 900 --output-dir /tmp/settings-matrix-portrait-lower`
- laptop lower-fold matrix:
  - `scripts/capture-settings-matrix.sh --preset laptop --scroll-y 700 --output-dir /tmp/settings-matrix-laptop-lower`

## Manual Visual QA Matrix

Validate the settings hub in three viewport classes:

- large landscape,
- standard laptop landscape,
- narrow or portrait.

For each class, verify:

- the hub stays inside reserved screen edges,
- the larger modal sizing feels balanced,
- compact icon rail activates only on narrow/portrait layouts,
- compact search appears in the content header,
- wide sidebar search still works,
- `Esc`, overlay click, and `Save & Close` still work.
- where content is long, inspect both the initial fold and a lower section using `--scroll-y`.

## High-Risk Tabs

Prioritize these tabs during manual QA:

1. `Wallpaper`
2. `Bar Widgets`
3. `Bars`
4. `System`
5. `Plugins`
6. `Theme`
7. `Keybinds`
8. `Time & Weather`

Look for:

- horizontal clipping,
- unreadable truncation,
- bad wrap order in chip/button groups,
- oversized vertical spacing after wrapping,
- dialogs or pickers exceeding the viewport,
- search result alignment issues.
- in `Bar Widgets`, verify CPU / Memory / GPU rows show both `Mode` and `Value` summary chips.
- in `Bar Widgets`, open CPU / Memory / GPU settings and verify `Display Mode` and `Value Style` controls wrap cleanly in portrait/narrow layouts.
- in `Bar Widgets`, verify compact and auto modes remain readable when long values are selected and that compact mode shortens long values instead of widening the layout.
- in `Bar Widgets`, open `Add Widget` from left, center, and right and verify the picker shows the full widget catalog with search working across names/descriptions.
- in desktop widget edit mode, verify `Add Widget` opens the searchable catalog and that built-in and plugin desktop widgets appear in the same list.

## Harness Notes

- The viewport capture harness is valid for layout inspection, but it does not perfectly reproduce every runtime data source.
- The synthetic `Bar Widgets` smoke harness now mirrors the real settings subtree so sibling QML types resolve the same way they do in the shipped settings UI.
- In headless/offscreen runs, that harness should now either load normally or stop on the expected `No PanelWindow backend loaded` condition rather than failing on malformed temporary import paths.
- `Theme` is the known exception:
  - in the real running `SettingsHub`, the theme list populates normally,
  - in the harness, the tab can report `0 themes`,
  - treat that as a harness-data limitation, not a confirmed layout regression.
- `Bar Widgets` stat-widget settings are now partially protected by the headless-safe config contract check:
  - `scripts/check-panel-config-contracts.sh`
  - use that for default/migration coverage,
  - use live preview/capture for final layout validation.
- Add-widget picker behavior is now protected by a dedicated headless harness:
  - `scripts/check-widget-picker-search.sh`
  - this verifies full-catalog visibility and search narrowing for both bar and desktop widget pickers.
- For `Theme`, use the live shell preview path for final validation:
  - `scripts/preview-settings-responsive.sh`
  - or open `SettingsHub` directly in the running shell and inspect the tab there.

## Triage Format

Record remaining issues in this format:

- screen shape: wide, laptop, narrow, or portrait
- tab: exact settings tab name
- defect: clipping, awkward wrapping, oversized spacing, or broken interaction
- severity: blocking, awkward, or cosmetic

## Acceptance Criteria

- No horizontal clipping in primary settings flows.
- No important labels become unreadable in compact mode.
- Action groups remain usable after wrapping.
- Dialogs and pickers remain inside the visible viewport.
- Search navigation works in wide and compact modes.
- Placement remains screen-safe relative to reserved edges.
- CPU / Memory / GPU widget settings remain readable and configurable in compact layouts.
