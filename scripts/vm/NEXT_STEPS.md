# Niri Test VM Next Steps

This document captures the most useful follow-on work for the `niriTestVm` path.

## Current State

The VM path is in a usable state:

- `niriTestVm` builds and launches
- SDDM autologins to `niri`
- the dedicated Home Manager profile is stripped down for compositor testing
- `quickshell` and `kitty` start automatically
- the VM smoke check passes with `make niri-vm-smoke`

The VM is now good enough for repeatable Niri and Quickshell validation, but there is still useful cleanup and productization work left.

## Phase 1: Tighten Validation

Goal: make the VM a stronger regression gate instead of just a manual test environment.

Tasks:

1. Extend the smoke check to validate Quickshell health.
   - Check that Quickshell loads the expected config.
   - Fail on known-fatal startup errors.
   - Keep warnings informational unless they are known regressions.

2. Add a "keep running on success" mode.
   - Example: `NIRI_VM_SMOKE_KEEP_RUNNING=1 make niri-vm-smoke`
   - Useful when a smoke run passes and you want to inspect the live VM manually.

3. Add a verbose mode.
   - Print the launcher log path.
   - Print the recent system journal in addition to the user journal.
   - Make failures easier to diagnose without rerunning manually.

4. Add a stable artifact/log directory.
   - Store smoke logs under `~/.local/state/nixos-config/niri-test-vm/`
   - Keep the latest launcher log and smoke summary in a predictable location.

## Phase 2: Reduce Remaining Session Noise

Goal: keep the VM focused on compositor and shell behavior.

Tasks:

1. Review the remaining portal and WirePlumber warnings.
   - `org.bluez` / BlueZ-related messages are expected today because Bluetooth is disabled.
   - Decide whether to keep them as accepted noise or suppress them in the VM profile.

2. Review XWayland behavior.
   - Niri logs that `xwayland-satellite` is missing.
   - Decide whether the VM should:
     - remain Wayland-only, or
     - include XWayland support for broader application testing.

3. Review whether GNOME keyring is needed in the VM.
   - If not needed for Quickshell/Niri validation, disable it to simplify startup further.

4. Decide whether the VM should keep GTK/GNOME portals or move to a smaller portal set.
   - Current setup is functional.
   - Smaller portal scope may reduce noise and startup complexity.

## Phase 3: Improve Visual Testing

Goal: make it easier to catch layout and compositor regressions, not just startup failures.

Tasks:

1. Add an optional screenshot capture path.
   - Boot VM.
   - Wait for `niri` + `quickshell` + `kitty`.
   - Capture the VM window or session surface for comparison.

2. Add a Quickshell-specific visual smoke.
   - Verify the panel appears.
   - Verify key surfaces render without fatal QML/runtime errors.

3. Add fixture scenarios.
   - terminal only
   - terminal + browser
   - multiple windows/workspaces
   - common panel interactions

4. Decide whether this VM should be used for screenshot baselines.
   - If yes, lock down font/rendering inputs as much as possible.

## Phase 4: Integrate With Project Workflows

Goal: make this useful beyond ad hoc local debugging.

Tasks:

1. Add a top-level documented workflow for Niri-specific regression testing.
   - Example flow:
     - `make niri-vm-build`
     - `make niri-vm-smoke`
     - `make niri-vm-fresh` for manual inspection if smoke passes

2. Decide whether to add this to CI.
   - Local-only may be enough if CI GPU/QEMU support is awkward.
   - If CI is desired, start with build-only and smoke-only stages before visual checks.

3. Connect the VM checks to Quickshell change areas.
   - launcher
   - panel
   - notifications
   - settings

4. Add a short maintainer guide for updating the dedicated VM profile safely.
   - what belongs in `home/niriTestVm.nix`
   - what should stay in `woody`
   - what should be VM-only system overrides in `flake.nix`

## Recommended Order

The most practical next sequence is:

1. Extend `make niri-vm-smoke` with Quickshell-specific checks.
2. Add keep-running and verbose smoke modes.
3. Decide whether to keep or suppress the remaining portal/BlueZ/XWayland warnings.
4. Add one visual capture path for manual regression comparison.
5. Decide whether any of this should move into CI.

## Success Criteria

This work is in a good place when:

- the VM boots reliably with one command
- smoke checks catch startup regressions automatically
- Quickshell startup issues are surfaced directly by the smoke harness
- the VM session remains intentionally minimal
- maintainers know which layer to modify for VM-specific behavior
