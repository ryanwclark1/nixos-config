# Quickshell Next Steps

Use this document to drive the next work after the bar widget management, typography normalization, and runtime QA fixes completed in this pass.

## Current Baseline

- Bar widget value typography is normalized across the comparable bar widgets.
- The `Bar Widgets` settings tab now shows the current widgets for the selected bar.
- The `Bar Widgets` tab now has explicit drag handles and drop targets for:
  - reordering within a section
  - moving to another section
  - dropping into an empty section
  - dropping at the end of a section
- `Config.moveBarWidget(...)` now supports cross-section moves.
- `PrinterService.qml` no longer breaks the config contract harness.
- `quickshell.service` was restarted successfully on the current Home Manager generation and is healthy again.

## Evidence Collected

- Live installed-shell capture confirms populated widget management UI:
  - `/tmp/bar-widgets-installed-live.png`
- Live settings smoke passed against the installed shell:
  - `scripts/check-settings-responsive.sh --id <live-instance>`
- Config contract checks passed:
  - `scripts/check-panel-config-contracts.sh`
- The multibar QA script now supports running only the management harnesses:
  - `scripts/check-multibar-smoke.sh --management-only`

## What Is Still Not Fully Proven

- An end-to-end drag gesture has not been mechanically exercised from automation yet.
- The management harnesses now skip cleanly in this environment because offscreen QuickShell has no `PanelWindow` backend.
- The full synthetic shell matrix remains separate from this bar-widget verification and can still be blocked by unrelated shell-level issues.

## Immediate Next Work

### 1. Manually prove drag and drop in the live installed shell

Do this first. It is the main remaining verification gap.

Check these scenarios:

- drag a widget upward within the same section
- drag a widget downward within the same section
- move a widget from `left` to `center`
- move a widget from `left` or `center` into an empty section
- drop a widget at the end of a populated section
- confirm the order persists after closing and reopening Settings
- confirm the order persists after `Shell.reloadConfig`

Success criteria:

- widget order changes immediately in the settings list
- the visible bar layout updates to match
- no duplicate widgets appear
- no widget disappears unexpectedly
- moved widgets remain configurable and removable after the move

### 2. Capture post-move evidence

After manual drag verification, save concrete artifacts:

- one screenshot before a move
- one screenshot after a same-section reorder
- one screenshot after a cross-section move

Recommended artifact names:

- `/tmp/bar-widgets-before-move.png`
- `/tmp/bar-widgets-after-reorder.png`
- `/tmp/bar-widgets-after-cross-section-move.png`

### 3. Verify persistence in config state

After moving widgets manually, verify that persisted bar config reflects the new order.

Check:

- selected bar section widget ordering in the QuickShell config state
- behavior after settings close/reopen
- behavior after panel service restart

If persistence fails, inspect:

- `config/services/Config.qml`
- update paths triggered by `updateBarSection(...)`
- any save/debounce path tied to config writes

## Follow-Up Engineering Work

### 4. Add stronger automated verification for bar widget moves

Preferred path:

- extend existing QA tooling rather than adding permanent debug-only runtime hooks

Practical options:

- add a repo-shell or live-session helper that can programmatically mutate bar config order and then capture the `Bar Widgets` tab
- add a dedicated verification helper for `Config.moveBarWidget(...)`
- if needed, add a temporary IPC bridge only for local QA, but do not keep unnecessary runtime surface area

Success criteria:

- one repeatable command can prove at least one same-section reorder
- one repeatable command can prove at least one cross-section move

### 5. Improve drag/drop affordance clarity if manual QA shows ambiguity

Potential polish items:

- stronger drop indicator before hovered rows
- stronger end-of-section drop target styling
- clearer empty-section drop messaging
- clearer active drag state on the source card
- larger or more obvious drag handle hit target if needed

Do this only after live interaction feedback, not by assumption.

### 6. Broaden typography consistency only if desired

This pass normalized the primary comparable bar values. A second pass could standardize:

- clock/date hierarchy
- badge text such as status chips
- compact stat labels
- other bar text that still intentionally differs

This is a separate visual refactor, not required for the bar widget drag/drop work.

## QA Commands

Use these as the current verification baseline:

```bash
bash ./home/features/desktop/window-managers/shared/panel/quickshell/scripts/check-panel-config-contracts.sh
```

```bash
bash ./home/features/desktop/window-managers/shared/panel/quickshell/scripts/check-settings-responsive.sh --id <live-instance>
```

```bash
bash ./home/features/desktop/window-managers/shared/panel/quickshell/scripts/check-multibar-smoke.sh --management-only
```

```bash
bash ./home/features/desktop/window-managers/shared/panel/quickshell/scripts/capture-settings-viewport.sh --id <live-instance> --tab bar-widgets --output /tmp/bar-widgets-installed-live.png
```

## Open Questions

- Do we want a permanent automated move-verification tool for bar widget ordering?
- Should drag/drop verification become part of the standard panel QA checklist for settings-surface changes?
- Should the `Bar Widgets` tab expose a more explicit reorder mode if users miss the drag handle?

## Launcher Settings Ordering Track

Detailed tracker:

- `LAUNCHER_SETTINGS_NEXT_STEPS.md`

This pass also added drag-and-drop ordering to the `System` settings tab for:

- launcher mode order
- web provider order

The `↑` / `↓` controls remain in place as fallback.

### Evidence Collected

- Static launcher responsive guardrails passed:
  - `scripts/check-launcher-responsive.sh`
- Launcher performance check passed:
  - `scripts/check-launcher-performance.sh`
- Live QuickShell IPC was reachable for the active session.
- A live `System` tab runtime capture succeeded on the current workspace:
  - `/tmp/quickshell-system-tab-runtime.png`

### What Is Still Not Fully Proven

- Drag-and-drop has not yet been reviewed across portrait, laptop, and wide settings layouts.
- The current-workspace capture path works, but auto-workspace capture failed once with:
  - `Workspace 9001 did not become active in time.`
- There is not yet a guardrail that explicitly checks the ordering rows keep both drag affordances and arrow-button fallback.

### Immediate Next Work

#### 1. Review the `System` tab live across target viewports

Do this first. It is the main remaining gap for the launcher ordering UI.

Capture and review:

- portrait `System` tab
- laptop `System` tab
- wide `System` tab

Recommended command pattern:

```bash
bash ./home/features/desktop/window-managers/shared/panel/quickshell/scripts/capture-settings-viewport.sh --id <live-instance> --workspace current --tab system --output /tmp/system-tab-runtime.png
```

Success criteria:

- drag handles are visually distinct from the actual mode/provider icons
- drop indicators are visible and feel intentional
- compact mode does not cause text/button overlap
- dragging to the end of the list feels stable
- `↑` / `↓` buttons still work after drag UI changes

#### 2. Manually exercise the new ordering flows

Check:

- move one launcher mode upward
- move one launcher mode downward
- move one web provider upward
- move one web provider downward
- drag to the first slot
- drag to the end slot
- confirm order persists after closing/reopening Settings
- confirm order persists after `Shell.reloadConfig`

Success criteria:

- order updates immediately in the settings list
- no duplicate rows appear
- no row disappears unexpectedly
- persisted order matches the UI after reload

#### 3. Harden the capture workflow if this path will be reused

If launcher settings work continues, tighten the tooling instead of relying on ad hoc commands.

Best candidates:

- make `capture-settings-viewport.sh --workspace auto` more reliable
- add a tiny helper focused on `System` tab capture
- add one guardrail for ordering-row affordance preservation

### Open Questions For This Track

- Should the mode-order and provider-order rows be refactored into one reusable drag-sort component?
- Should live `System` tab capture become a required artifact for launcher-settings UI changes?
- Should drag-and-drop verification move into `STRUCTURE_CHECKLIST.md` for settings-surface work?
