# Settings Responsive Closeout

## Scope

This closeout records the responsive settings-hub work completed across:

- `SettingsHub`
- shared settings shell/navigation
- shared settings primitives
- dense settings tabs
- runtime smoke tooling
- simulated viewport capture tooling

## Implemented Changes

- Increased the settings hub size cap and made sizing screen-aware.
- Added compact-mode behavior for narrow and portrait layouts.
- Made search responsive across wide and compact modes.
- Removed fixed-height and fixed-row assumptions from shared settings primitives.
- Hardened dense tabs including:
  - `Wallpaper`
  - `Bar Widgets`
  - `Bars`
  - `System`
  - `Plugins`
  - `Theme`
  - `Hotkeys`
  - `Time & Weather`
- Added runtime guardrail scripts and viewport capture scripts for regression checking.
- Hardened capture tooling so viewport/surface runs choose reachable QuickShell and Hyprland sessions and wait for workspace activation before capturing.
- Fixed repo-shell/runtime regressions uncovered during verification:
  - deferred settings tab open now guards persistence state initialization,
  - `CommandPoll` no longer emits startup `triggerPoll` type errors,
  - missing shared settings/bar support widgets were restored where refactors had left dangling references.

## QA Evidence

### Runtime Guardrails

- `scripts/check-settings-guardrails.sh`
- `scripts/check-settings-responsive.sh`
- `scripts/preview-settings-responsive.sh`

Latest verification result:

```text
[PASS] IPC reachable for pid 3701012
[PASS] Shell.reloadConfig
[PASS] SettingsHub.open
[PASS] SettingsHub.openTab wallpaper
[PASS] SettingsHub.openTab bar-widgets
[PASS] SettingsHub.openTab bars
[PASS] SettingsHub.openTab system
[PASS] SettingsHub.openTab plugins
[PASS] SettingsHub.openTab theme
[PASS] SettingsHub.openTab hotkeys
[PASS] SettingsHub.openTab time-weather
[PASS] No new runtime warnings/errors in QuickShell log
[INFO] Summary: 12 pass, 0 warn, 0 fail
```

### Simulated Viewport QA

Validated with:

- `scripts/capture-settings-matrix.sh --preset portrait`
- `scripts/capture-settings-matrix.sh --preset portrait --scroll-y 900`
- `scripts/capture-settings-matrix.sh --preset laptop`
- `scripts/capture-settings-matrix.sh --preset laptop --scroll-y 700`

These runs covered both first-fold and lower-fold content for long tabs.

### Live Validation

Verified directly in the running shell for:

- `Theme`
- `System`

This confirmed:

- the live `Theme` tab populates correctly with real theme data,
- the `System` launcher-section overlap found in laptop harness QA was fixed.

## Defects Found During QA

### Fixed

- `System` launcher toggle grid overlapped at laptop-width lower-fold capture.
  - Fix: increased the local `SettingsFieldGrid` threshold to keep that block single-column until it has enough width.

### Known Harness Limitation

- The viewport harness can show `0 themes` in `Theme`.
- This is not treated as a production defect.
- Live `SettingsHub` validation showed the theme list rendering normally.

## Final Status

- Responsive settings implementation: complete
- Runtime smoke gate: complete
- Portrait/laptop lower-fold capture workflow: complete
- Live validation of remaining uncertain tabs: complete
- Checklist/runbook integration: complete
- Repo-shell settings runtime verification: complete

## Future Workflow

For future changes to responsive settings surfaces:

1. Run `scripts/check-settings-guardrails.sh`
2. Review portrait lower-fold captures
3. Review laptop lower-fold captures
4. Use live shell validation for `Theme`
5. Patch only concrete regressions

## 2026-03-16 Launcher Settings Split

### Scope

- Split the single launcher settings page into dedicated sidebar pages under the existing `Launcher` category:
  - `General`
  - `Search`
  - `Web`
  - `Modes`
  - `Runtime`
- Extended settings smoke, preview, and capture tooling so those page ids are exercised directly.

### Implemented Changes

- Added launcher tab entries in `SettingsRegistry.qml` for:
  - `launcher`
  - `launcher-search`
  - `launcher-web`
  - `launcher-modes`
  - `launcher-runtime`
- Reused `ShellCoreSectionTab.qml` for the launcher subpages by introducing dedicated launcher section modes instead of duplicating config logic.
- Updated:
  - `scripts/check-settings-responsive.sh`
  - `scripts/preview-settings-responsive.sh`
  - `scripts/capture-settings-matrix.sh`
  - `SETTINGS_RESPONSIVE_RUNBOOK.md`
  so the launcher split is part of normal settings QA coverage.

### Verification

Verification completed on `2026-03-16 18:15:24 CDT`.

`scripts/check-settings-guardrails.sh`:

```text
[PASS] IPC reachable for pid 1119931
[PASS] Shell.reloadConfig
[PASS] SettingsHub.open
[PASS] SettingsHub.openTab launcher
[PASS] SettingsHub.openTab launcher-search
[PASS] SettingsHub.openTab launcher-web
[PASS] SettingsHub.openTab launcher-modes
[PASS] SettingsHub.openTab launcher-runtime
[PASS] SettingsHub.openTab wallpaper
[PASS] SettingsHub.openTab bar-widgets
[PASS] SettingsHub.openTab bars
[PASS] SettingsHub.openTab system
[PASS] SettingsHub.openTab plugins
[PASS] SettingsHub.openTab theme
[PASS] SettingsHub.openTab hotkeys
[PASS] SettingsHub.openTab time-weather
[PASS] Only known non-blocking runtime warnings were observed
[INFO] Summary: 17 pass, 0 warn, 0 fail
Settings guardrails passed.
```

`scripts/check-launcher-guardrails.sh`:

```text
Launcher keymap check passed.
Launcher tab matrix check passed.
Launcher web alias check passed.
Launcher category filters check passed.
Launcher performance check passed.
Launcher guardrail checks passed.
```

Repo-shell-backed artifact generation:

```text
./scripts/capture-panel-matrix.sh --repo-shell --skip-surfaces --settings-preset portrait --output-dir /tmp/panel-qa-launcher-split-padding-test
[INFO] Repo shell instance ready: tomj10jm0ct
[INFO] Saved panel QA review artifacts to /tmp/panel-qa-launcher-split-padding-test
[INFO] Saved review gallery to /tmp/panel-qa-launcher-split-padding-test/index.html
```

Launcher portrait artifacts produced:

- `/tmp/panel-qa-launcher-split-padding-test/settings-portrait/portrait-launcher.png`
- `/tmp/panel-qa-launcher-split-padding-test/settings-portrait/portrait-launcher-search.png`
- `/tmp/panel-qa-launcher-split-padding-test/settings-portrait/portrait-launcher-web.png`
- `/tmp/panel-qa-launcher-split-padding-test/settings-portrait/portrait-launcher-modes.png`
- `/tmp/panel-qa-launcher-split-padding-test/settings-portrait/portrait-launcher-runtime.png`

Launcher portrait lower-fold artifacts produced:

- `/tmp/panel-qa-launcher-split-padding-test/settings-portrait-deep/portrait-launcher.png`
- `/tmp/panel-qa-launcher-split-padding-test/settings-portrait-deep/portrait-launcher-search.png`
- `/tmp/panel-qa-launcher-split-padding-test/settings-portrait-deep/portrait-launcher-web.png`
- `/tmp/panel-qa-launcher-split-padding-test/settings-portrait-deep/portrait-launcher-modes.png`
- `/tmp/panel-qa-launcher-split-padding-test/settings-portrait-deep/portrait-launcher-runtime.png`

### Notes

- A direct live-shell `capture-settings-matrix.sh` run initially failed after `wallpaper` because the ambient QuickShell instance disappeared mid-run.
- The repo-shell wrapper path completed successfully and is the preferred artifact path when the managed service is unstable or being reloaded during QA.
- Settings modal captures now include extra padding so the full left sidebar remains visible instead of being clipped at the left edge.
- The final padded gallery at `/tmp/panel-qa-launcher-split-padding-test/index.html` was visually reviewed and accepted.
- Older temporary capture directories from earlier failed/tight-crop runs are superseded by the padded gallery and can be removed when command policy allows:
  - `/tmp/panel-qa-launcher-split`
  - `/tmp/panel-qa-launcher-split-rerun`
  - `/tmp/panel-qa-launcher-split-rerun-fixed`

## Out Of Scope

- Additional broad settings refactors without a reproduced defect
- New settings size preferences or user-facing layout toggles
- Full-screen redesign of the settings hub
