# Panel Next Steps

This document captures the next work for the shared QuickShell panel after the multi-bar expansion, responsive settings work, managed Home Manager recovery, and current QA tooling pass.

It is intentionally action-oriented. The goal is to finish the remaining validation and capture issues without reopening architecture or config-schema work.

## Current State

Managed shell status:

- `quickshell.service` is healthy again on the Home Manager path.
- The live managed shell loads from the current HM store config and reaches `Configuration Loaded`.
- `home-manager switch --flake .#administrator@woody --show-trace --verbose` completed successfully.

Runtime status:

- config contract checks pass
- settings smoke passes, including repo-shell validation through:
  - `scripts/check-panel-runtime.sh --repo-shell --skip-surfaces --skip-multibar`
- live surface smoke passes
- synthetic multibar smoke is still environment-sensitive and can `[SKIP]` in headless/offscreen runs when no `PanelWindow` backend is available

UI status:

- multi-bar config and per-bar widget management are implemented
- shared settings drag/reorder primitives now back the active reorder surfaces
- settings modal ghosting was addressed by moving settings surfaces onto opaque modal tokens
- portrait settings captures are usable again
- managed-shell capture gallery generation works

Known remaining defect:

- surface screenshot capture is still not reliably isolating the intended popup bounds for all popup classes
- settings capture is in better shape than surface capture
- repo-shell settings capture is currently blocked in this shell environment with:
  - `failed to create display`

## Immediate Priority

### 1. Finish surface capture correctness

This is the main unresolved tooling bug.

What is already true:

- the capture path now prefers `surface` crops over whole-monitor crops
- `surface` mode no longer depends on the empty-workspace path
- the script can resolve Hyprland layer metadata

What is still wrong:

- some surface captures still select the wrong QuickShell layer
- menu-class and panel-class surfaces are not yet filtered consistently
- the resulting artifact can still show too much of the desktop instead of the popup itself

Required work:

1. instrument `scripts/capture-surface-viewport.sh` to log:
   - resolved live instance id
   - resolved shell pid
   - focused monitor
   - candidate layer entries
   - chosen crop box
2. compare at least these surfaces:
   - `controlCenter`
   - `notifCenter`
   - `networkMenu`
   - `weatherMenu`
   - `dateTimeMenu`
3. tighten the layer selector so it chooses the actual popup surface instead of the root shell layer or unrelated QuickShell layers
4. keep the fix local to capture tooling; do not change popup runtime code unless the evidence shows the shell itself is emitting the wrong layers

Acceptance criteria:

- `controlCenter` capture shows the control center panel, not the full desktop
- `networkMenu` capture shows the network popup, not the full desktop
- the same rule works across both large edge panels and small popup menus

### 2. Regenerate the managed-shell artifact set

Once the surface crop bug is fixed:

1. rerun `qs-panel-capture-matrix`
2. verify the generated `index.html`
3. spot-check the same high-risk files:
   - `settings-portrait/portrait-system.png`
   - `settings-portrait/portrait-bar-widgets.png`
   - `surfaces-monitor/notifCenter-*.png`
   - `surfaces-monitor/controlCenter-*.png`
   - `surfaces-monitor/networkMenu-*.png`
   - `surfaces-monitor/weatherMenu-*.png`

Acceptance criteria:

- settings captures remain clean
- surface captures are focused on the popup itself
- the gallery is useful for defect review without manual explanation

## Next Validation Phase

### 3. Manual visual QA on the managed shell

Once managed-shell captures are trustworthy again, return to live manual QA on the HM-managed shell instead of the repo-shell fallback.

Use:

- `qs-panel-runtime-verify`
- `qs-panel-preview`
- `qs-panel-capture-matrix`

Validate:

- top bar popup anchoring
- bottom bar popup anchoring
- left bar popup anchoring
- right bar popup anchoring
- Notification Center behavior from different edges
- Control Center behavior from different edges
- dock coexistence with bars on mixed monitor layouts
- bar settings and bar widget settings in portrait/narrow layouts

Record only concrete defects:

- exact surface or tab
- exact bar edge
- exact monitor/layout shape
- screenshot if available

## Next Fix Phase

### 4. Convert manual QA findings into narrow fixes

Only after the surface artifact set is trustworthy.

Expected likely fix buckets:

1. anchor placement mismatches on left/right bars
2. spacing issues in compact popup layouts
3. remaining capture-only bugs in QA tooling
4. drag/reorder interaction issues in bar widget management

Rules for this phase:

- do not reopen schema design
- do not refactor config structure
- do not broaden scope beyond observed defects
- fix one concrete failure at a time and rerun the smallest relevant verification path

## Documentation Follow-up

### 5. Update the runbooks after the capture bug is fixed

Once `surface` crop mode is trustworthy:

1. update `PANEL_QA_RUNBOOK.md`
2. update `SURFACE_RESPONSIVE_RUNBOOK.md`
3. change examples that still recommend `--surface-crop monitor`
4. document when `surface`, `usable`, and `monitor` crops should each be used

## Deferred Work

These are not current priorities:

- new bar features or schema changes
- additional large launcher redesign work
- replacing the QA workflow again
- broad refactors unrelated to observed failures

## Suggested Execution Order

1. fix `capture-surface-viewport.sh` layer selection
2. rerun `qs-panel-capture-matrix` on the managed shell
3. review the managed gallery
4. run `qs-panel-preview`
5. fix only concrete defects found during that review
6. update the runbooks to reflect the final capture mode guidance

## Exit Criteria

This panel effort can move out of stabilization when all of the following are true:

- managed `quickshell.service` remains healthy after Home Manager apply
- `qs-panel-runtime-verify` passes on the managed shell
- managed `qs-panel-capture-matrix` produces trustworthy popup-focused artifacts
- manual QA on top, bottom, left, and right bars does not reveal blocking placement regressions
- remaining issues are cosmetic or explicitly deferred
