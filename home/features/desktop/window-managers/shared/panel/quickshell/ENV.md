# QuickShell environment variables

Runtime and tooling variables used by this panel. Values set from Nix are defined in [default.nix](default.nix) (`home.sessionVariables`, `systemd.user.services.quickshell`).

| Variable | Purpose |
|----------|---------|
| `QS_NIXOS_CONFIG` | Absolute path to the flake / nixos-config repository root. Used by [SystemStatus.qml](src/services/SystemStatus.qml) to locate `scripts/` for health checks and plugin doctor when `QS_SCRIPT_ROOT` is unset. Set automatically when using the Home Manager module; override if your checkout lives outside `~/nixos-config`. |
| `QS_SCRIPT_ROOT` | Optional override for the directory containing `health-check.sh` and `plugin-doctor.sh`. When empty, defaults to `$QS_NIXOS_CONFIG/home/features/desktop/window-managers/shared/panel/quickshell/scripts` (or the same path derived from `HOME` when `QS_NIXOS_CONFIG` is unset). |
| `QS_CONFIG_DIR` | Quickshell config directory (deployed QML tree). Set by the launch wrapper. |
| `QS_FIXTURES_DIR` | Test/fixture assets path. Set by the launch wrapper. |
| `QS_NIRI_PARSER` | Path to the Niri keybind parser script (Nix-provided). |

Other `QS_*` prefixes may appear in scripts (for example verification timeouts in `scripts/quickshell-structure-verify.sh`); see those files for details.

## Code helpers

- [ShellUtils.js](src/services/ShellUtils.js) `ipcCall(target, method, ...args)` builds the `quickshell ipc call` argv array used with `Quickshell.execDetached`. Shared launcher shortcuts live in [LauncherShellIpcActions.js](src/launcher/LauncherShellIpcActions.js).
