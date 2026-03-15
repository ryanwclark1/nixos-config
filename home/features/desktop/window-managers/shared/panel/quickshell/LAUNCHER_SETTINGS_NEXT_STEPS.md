# Launcher Settings Next Steps

This document tracks follow-up work for the `System` settings tab launcher-ordering changes in QuickShell.

## Scope

This covers the launcher-related ordering controls in:

- `config/menu/settings/tabs/SystemTab.qml`

Specifically:

- launcher mode order
- web provider order
- drag-and-drop interaction
- `↑` / `↓` fallback controls

## Current State

Implemented:

- drag-and-drop ordering for launcher modes
- drag-and-drop ordering for web providers
- shared settings drag handles in both ordering lists
- mapped-position reorder math shared through `SettingsReorder.js`
- end-of-list drop indicators for both ordering lists
- existing arrow-button reorder controls preserved as fallback

Validated:

- `qmlformat -i home/features/desktop/window-managers/shared/panel/quickshell/config/menu/settings/tabs/SystemTab.qml`
- `bash home/features/desktop/window-managers/shared/panel/quickshell/scripts/check-launcher-performance.sh`
- `bash home/features/desktop/window-managers/shared/panel/quickshell/scripts/check-launcher-responsive.sh --ci`
- `bash home/features/desktop/window-managers/shared/panel/quickshell/scripts/check-panel-runtime.sh --repo-shell --skip-surfaces --skip-multibar`
  - includes passing `SettingsHub.openTab system`

Known limitation:

- settings capture is blocked in the current shell environment because repo-shell capture failed with:
  - `failed to create display`
- `capture-settings-viewport.sh --workspace auto` still needs validation in a real graphical session.

## Remaining Gaps

The main unresolved items are QA gaps, not implementation gaps.

Still needs proof:

- portrait layout review
- laptop layout review
- wide layout review
- real drag/drop interaction across both ordering lists
- persistence after settings close/reopen
- persistence after `Shell.reloadConfig`

Still needs decision:

- whether the current drag affordance is visually strong enough in compact mode
- whether the end-of-list drop target is obvious enough
- whether this duplicated drag-sort pattern should become a reusable component

## Recommended Next Work

### 1. Capture the `System` tab across target viewports

Capture and review:

- portrait
- laptop
- wide

Suggested command pattern:

```bash
bash ./home/features/desktop/window-managers/shared/panel/quickshell/scripts/capture-settings-viewport.sh --id <live-instance> --workspace current --tab system --output /tmp/system-tab-runtime.png
```

Review criteria:

- drag handles do not read like launcher/provider icons
- row text stays readable in compact layouts
- arrow buttons remain reachable and legible
- drop indicators are visible but not visually noisy

### 2. Manually verify drag-and-drop behavior

Check these scenarios:

- move a launcher mode upward
- move a launcher mode downward
- move a launcher mode to the first slot
- move a launcher mode to the last slot
- move a web provider upward
- move a web provider downward
- move a web provider to the first slot
- move a web provider to the last slot

Success criteria:

- the list updates immediately
- no duplicate rows appear
- no row disappears unexpectedly
- drop target behavior is predictable

### 3. Verify persistence

After manual moves:

- close and reopen `Settings`
- run `Shell.reloadConfig`
- confirm the displayed order remains correct

If persistence fails, inspect:

- `config/services/Config.qml`
- launcher mode order save path
- launcher web provider order save path

### 4. Improve runtime QA tooling

If this area will keep changing, add stronger verification instead of relying on manual memory.

Best candidates:

- add a guardrail that checks `SystemTab.qml` still exposes:
  - drag handles
  - arrow-button fallback
- harden `capture-settings-viewport.sh --workspace auto`
- add a small helper focused on `System` tab capture when a graphical session is available

### 5. Consider refactoring the duplicated drag-sort pattern

Mode ordering and provider ordering now use the same interaction pattern, but the implementation is duplicated.

Only do this if the UI will continue to evolve.

Refactor target:

- a shared drag-sort row helper for settings lists

## Evidence

Commands already run during this pass:

```bash
qmlformat -i home/features/desktop/window-managers/shared/panel/quickshell/config/menu/settings/tabs/SystemTab.qml
```

```bash
bash home/features/desktop/window-managers/shared/panel/quickshell/scripts/check-launcher-performance.sh
```

```bash
bash home/features/desktop/window-managers/shared/panel/quickshell/scripts/check-launcher-responsive.sh --ci
```

```bash
bash home/features/desktop/window-managers/shared/panel/quickshell/scripts/check-panel-runtime.sh --repo-shell --skip-surfaces --skip-multibar
```

## Open Questions

- Should launcher settings ordering changes require a live capture artifact before completion?
- Should drag-and-drop verification move into `STRUCTURE_CHECKLIST.md`?
- Should this settings ordering UI get a reusable component before more changes land?
