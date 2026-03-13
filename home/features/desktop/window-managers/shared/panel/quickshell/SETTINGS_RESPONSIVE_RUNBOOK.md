# Settings Responsive Runbook

Use this runbook after changes to the settings hub shell, shared settings primitives, or dense settings tabs.

Reference:

- historical closeout: `SETTINGS_RESPONSIVE_CLOSEOUT.md`

## Quick Commands

- Static + runtime guardrails:
  - `scripts/check-settings-guardrails.sh`
- Runtime smoke check against the live QuickShell instance:
  - `scripts/check-settings-responsive.sh`
- Manual tab preview for visual QA:
  - `scripts/preview-settings-responsive.sh`
- Simulated viewport screenshot capture:
  - `scripts/capture-settings-viewport.sh --width 430 --height 932 --tab wallpaper`
- Simulated lower-fold screenshot capture:
  - `scripts/capture-settings-viewport.sh --width 430 --height 932 --tab wallpaper --scroll-y 900`
- Batch viewport matrix capture:
  - `scripts/capture-settings-matrix.sh --preset portrait`
- Batch lower-fold viewport matrix capture:
  - `scripts/capture-settings-matrix.sh --preset portrait --scroll-y 900 --output-dir /tmp/settings-matrix-portrait-lower`
- If more than one QuickShell instance is running:
  - `scripts/check-settings-guardrails.sh --id <instance-id>`
  - `scripts/check-settings-responsive.sh --id <instance-id>`
  - `scripts/preview-settings-responsive.sh --id <instance-id>`
- Static parse validation for touched QML:
  - `qmlformat -n config/menu/SettingsHub.qml config/menu/settings/*.qml config/menu/settings/tabs/*.qml`

## What The Smoke Script Covers

The smoke script:

1. Locates a live QuickShell instance.
2. Calls `Shell.reloadConfig()`.
3. Opens `SettingsHub`.
4. Cycles the highest-risk tabs:
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

## Simulated Compact QA

Use the viewport capture script when you need repeatable narrow or portrait screenshots from a wide desktop session.

Examples:

- portrait phone-like width:
  - `scripts/capture-settings-viewport.sh --width 430 --height 932 --tab wallpaper`
- portrait tablet:
  - `scripts/capture-settings-viewport.sh --width 820 --height 1180 --tab system`
- compact tab check saved to a specific file:
  - `scripts/capture-settings-viewport.sh --width 430 --height 932 --tab plugins --output /tmp/plugins-portrait.png`
- compact lower-section check:
  - `scripts/capture-settings-viewport.sh --width 430 --height 932 --tab bar-widgets --scroll-y 900 --output /tmp/bar-widgets-portrait-lower.png`

Use this for visual inspection only. It does not replace the live runtime smoke gate.

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

## Harness Notes

- The viewport capture harness is valid for layout inspection, but it does not perfectly reproduce every runtime data source.
- `Theme` is the known exception:
  - in the real running `SettingsHub`, the theme list populates normally,
  - in the harness, the tab can report `0 themes`,
  - treat that as a harness-data limitation, not a confirmed layout regression.
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
