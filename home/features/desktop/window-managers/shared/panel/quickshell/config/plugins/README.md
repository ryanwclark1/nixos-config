# Shared Panel Plugin Manifest

Plugins are loaded from:

- `~/.config/quickshell/plugins/<plugin-id>/manifest.json`

Use `manifest.schema.json` as the reference contract for plugin manifests.

## Minimal launcher provider plugin

```json
{
  "id": "echoLauncher",
  "name": "Echo Launcher",
  "description": "Example launcher provider",
  "author": "you",
  "version": "1.0.0",
  "type": "launcher-provider",
  "permissions": ["settings_read", "settings_write"],
  "launcher": {
    "trigger": "#",
    "noTrigger": false
  },
  "entryPoints": {
    "launcherProvider": "LauncherProvider.qml"
  }
}
```

## Notes

- `type` can be `bar-widget`, `desktop-widget`, `launcher-provider`, `daemon`, or `multi`.
- `entryPoints` values must be `.qml` paths and must not contain `..`.
- Unknown/invalid manifests are rejected and surfaced in the Plugins settings tab.
- Plugin runtime status is exposed through `PluginService.pluginStatuses` with state/error metadata.
- Plugin state persistence uses a state envelope: `{ stateVersion, updatedAt, payload }`. Legacy plain object state files are auto-normalized.

## Validation Tooling

- Local runner:
  - `scripts/plugin-local.sh quick` (fast local guardrails, starting with `reference-all`)
  - `scripts/plugin-local.sh full` (complete local verification)
  - `scripts/plugin-local.sh doctor [/path/to/plugins]`
  - `scripts/plugin-local.sh install-reference [/path/to/plugins]`
  - `scripts/plugin-local.sh smoke-reference [/path/to/plugins]`
  - `scripts/plugin-local.sh remove-reference [/path/to/plugins]`
  - `scripts/plugin-local.sh reference-flow`
  - `scripts/plugin-local.sh reference-export`
  - `scripts/plugin-local.sh reference-status [/path/to/plugins]`
  - `scripts/plugin-local.sh reference-files`
  - `scripts/plugin-local.sh reference-guards`
  - `scripts/plugin-local.sh reference-all`
- Repo-tracked reference plugin:
  - `examples/plugins/reference-local-toolkit`
- Runtime state/error catalog:
  - `config/plugins/runtime-catalog.json`
- Diagnostics contract schema:
  - `config/plugins/diagnostics.schema.json`
- UI label/severity source: `PluginRuntimeCatalog` (`config/services/PluginRuntimeCatalog.qml`)
- Unified gate:
  - `scripts/plugin-verify.sh`
- Fixture conformance gate:
  - `scripts/check-plugin-conformance.sh`
- Plugin doctor smoke gate:
  - `scripts/check-plugin-doctor-smoke.sh`
- Plugin reference local gate:
  - `scripts/check-plugin-reference-local.sh`
- Plugin reference contract gate:
  - `scripts/check-plugin-reference-contracts.sh`
- Plugin reference fixture gate:
  - `scripts/check-plugin-reference-fixtures.sh`
- Plugin reference recovery gate:
  - `scripts/check-plugin-reference-recovery.sh`
- Plugin reference diagnostics gate:
  - `scripts/check-plugin-reference-diagnostics.sh`
- Plugin runtime guard gate:
  - `scripts/check-plugin-runtime-guards.sh`
- Plugin diagnostics contract gate:
  - `scripts/check-plugin-diagnostics-contracts.sh`
- Plugin diagnostics schema sync:
  - `scripts/sync-plugin-diagnostics-schema.sh --write`
  - CI/guard check: `scripts/sync-plugin-diagnostics-schema.sh --check`
- Plugin diagnostics schema gate:
  - `scripts/check-plugin-diagnostics-schema.sh`
  - uses the repo-local `scripts/validate-json-schema.js` helper (`nodejs`)
- Local plugin diagnosis:
  - `scripts/plugin-doctor.sh`
  - JSON output mode: `scripts/plugin-doctor.sh --json`
  - Optional custom path: `scripts/plugin-doctor.sh /path/to/plugins`

## Operational Diagnostics

- In Settings -> Plugins, use `Copy Diagnostics` to export a JSON snapshot to clipboard.
- In Settings -> Plugins, use `Save Diagnostics` to write a timestamped JSON snapshot under:
  - `~/.local/state/quickshell/plugin-diagnostics/`
- Export includes:
  - plugin summary counts
  - per-plugin manifest/runtime state
  - invalid manifest error list
- Use this snapshot when triaging plugin failures or sharing bug reports.
- Run `scripts/plugin-local.sh reference-export` to print the expected save path, fixture files, and reference export fields in the terminal.
- Run `scripts/plugin-local.sh reference-status` to print the full local reference-plugin command/fixture/diagnostics summary plus lightweight health status in one place.
- Run `scripts/plugin-local.sh reference-status --check` to fail fast when the local reference source, fixtures, or guard scripts are missing.
- Run `scripts/plugin-local.sh reference-status --check --quiet` when you want the preflight result without printing the full dashboard.
- Run `scripts/plugin-local.sh reference-status --quiet` when you want a one-line local availability summary for the reference toolkit.
- Run `scripts/plugin-local.sh reference-files` when you need only the canonical fixture and guard paths.
- Run `scripts/plugin-local.sh reference-guards` when you need only the runnable reference guard commands in order.
- Run `scripts/plugin-local.sh reference-all` when you want to execute the full reference-only guard sequence without the rest of `plugin-verify.sh`.
- Run `scripts/plugin-local.sh reference-all --quiet` when you want the reference-only guard sequence without stage headings.
- `scripts/plugin-local.sh quick` reuses `reference-all` before the shared runtime and diagnostics gates, so the fast path and the reference-only path stay aligned.

## Reference Plugin Workflow

- Install the repo-tracked reference plugin into a local plugin directory with `scripts/plugin-local.sh install-reference`.
- Validate the installed reference plugin in isolation with `scripts/plugin-local.sh smoke-reference`.
- Remove the linked reference plugin with `scripts/plugin-local.sh remove-reference`.
- Keep `scripts/check-plugin-reference-contracts.sh` green when changing the reference plugin so its intended manifest, state, launcher, and settings behaviors do not drift.
- Keep `scripts/check-plugin-reference-fixtures.sh` green when changing reference-plugin persistence so expected state-envelope and settings-key shapes do not drift.
- Keep `scripts/check-plugin-reference-recovery.sh` green when changing launcher failure handling so healthy, degraded, and recovery transitions remain aligned with `PluginService`.
- Keep `scripts/check-plugin-reference-diagnostics.sh` green when changing diagnostics export so the real reference plugin continues to produce stable active and degraded payload examples.
- `scripts/plugin-local.sh quick` is the fastest local way to catch reference-plugin and diagnostics/runtime contract drift together.
- Open launcher mode with `!ref` after installation to exercise increment, reset, and summary actions.
- Use the reference plugin settings page to toggle launcher failure modes (`query` or `execute`) and confirm degraded diagnostics in the Plugins tab.

## Reference Plugin Manual Flow

Run `scripts/plugin-local.sh reference-flow` to print this sequence in the terminal.

1. Run `scripts/plugin-local.sh install-reference` and `scripts/plugin-local.sh smoke-reference`.
2. Open Settings -> Plugins, confirm `Reference Local Toolkit` is present and enabled, then run `scripts/plugin-local.sh quick`.
3. Open launcher mode and query `!ref`, then run the `Increment`, `Reset`, and `Summary` actions.
4. Open the reference plugin settings page, cycle `Label`, toggle `Show Updated Marker`, and confirm the bar widget reflects the changes.
5. Set `Failure Mode` to `query`, re-run `!ref`, and confirm the plugin becomes `Degraded` with `E_LAUNCHER_QUERY`.
6. Use `Copy Diagnostics` and `Save Diagnostics`, then verify the exported payload shows `reference.local.toolkit` with degraded runtime metadata.
7. Set `Failure Mode` back to `none`, re-run `!ref`, and confirm the plugin returns to `Active`.
8. Repeat with `Failure Mode` set to `execute`, trigger an item, and confirm `E_LAUNCHER_EXECUTE`, then recover back to `none`.
9. Finish with `scripts/plugin-local.sh full` and `scripts/plugin-local.sh remove-reference`.
