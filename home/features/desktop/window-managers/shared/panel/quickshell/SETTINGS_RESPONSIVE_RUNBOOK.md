# Settings Responsive Runbook

Use this runbook after changes to the settings hub shell, shared settings primitives, or dense settings tabs.

## Quick Commands

- Runtime smoke check against the live QuickShell instance:
  - `scripts/check-settings-responsive.sh`
- If more than one QuickShell instance is running:
  - `scripts/check-settings-responsive.sh --id <instance-id>`
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
