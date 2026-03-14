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

- `type` can be `bar-widget`, `desktop-widget`, `launcher-provider`, `control-center-widget`, `daemon`, or `multi`.
- `entryPoints` values must be `.qml` paths and must not contain `..`.
- Control Center plugins may provide `entryPoints.controlCenterWidget` and optional `entryPoints.controlCenterDetail`.
- Control Center widgets are rendered inside the main Control Center surface and may declare any of these optional injected properties:
  - `pluginApi`
  - `pluginManifest`
  - `pluginService`
  - `controlCenterRoot`
  - `manager`
- Unknown/invalid manifests are rejected and surfaced in the Plugins settings tab.
- Plugin runtime status is exposed through `PluginService.pluginStatuses` with state/error metadata.
- Plugin state persistence uses a state envelope: `{ stateVersion, updatedAt, payload }`. Legacy plain object state files are auto-normalized.

## Validation Tooling

- Local runner:
  - `scripts/plugin-local.sh quick` (fast local guardrails, starting with `reference-all`)
  - `scripts/plugin-local.sh quick --quiet` (same fast local guardrails with compact output)
  - `scripts/plugin-local.sh full` (complete local verification)
  - `scripts/plugin-local.sh full --quiet` (same full verification with compact phase output)
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
  - `scripts/plugin-local.sh reference-all --quiet`
  - `scripts/plugin-local.sh install-docker-manager`
  - `scripts/plugin-local.sh smoke-docker-manager`
  - `scripts/plugin-local.sh remove-docker-manager`
  - `scripts/plugin-local.sh docker-status`
  - `scripts/plugin-local.sh docker-flow`
  - `scripts/plugin-local.sh docker-files`
  - `scripts/plugin-local.sh docker-guards`
  - `scripts/plugin-local.sh docker-all`
  - `scripts/plugin-local.sh shared-gates`
  - `scripts/plugin-local.sh shared-gates --quiet`
  - `scripts/plugin-local.sh baseline-gates`
  - `scripts/plugin-local.sh baseline-gates --quiet`
  - `scripts/plugin-local.sh all-gates`
  - `scripts/plugin-local.sh all-gates --quiet`
- Repo-tracked reference plugin:
  - `examples/plugins/reference-local-toolkit`
- Runtime state/error catalog:
  - `config/plugins/runtime-catalog.json`
- Diagnostics contract schema:
  - `config/plugins/diagnostics.schema.json`
- UI label/severity source: `PluginRuntimeCatalog` (`config/services/PluginRuntimeCatalog.qml`)
- Unified gate:
  - `scripts/plugin-verify.sh`
  - `scripts/plugin-verify.sh --quiet`
  - reuses `scripts/plugin-local.sh all-gates`
- Fixture conformance gate:
  - `scripts/check-plugin-conformance.sh`
- Plugin doctor smoke gate:
  - `scripts/check-plugin-doctor-smoke.sh`
- Plugin reference local gate:
  - `scripts/check-plugin-reference-local.sh`
- Plugin docker-manager local gate:
  - `scripts/check-plugin-docker-manager-local.sh`
- Plugin docker-manager runtime smoke gate:
  - `scripts/check-plugin-docker-manager-runtime-smoke.sh`
- Plugin docker-manager contract gate:
  - `scripts/check-plugin-docker-manager-contracts.sh`
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
- First-party SSH plugin gates:
  - `scripts/check-plugin-ssh-local.sh`
  - `scripts/check-plugin-ssh-runtime-smoke.sh`
  - `scripts/check-plugin-ssh-contracts.sh`
  - `scripts/check-plugin-ssh-fixtures.sh`
  - `scripts/plugin-local.sh ssh-status`
  - `scripts/plugin-local.sh ssh-status --check --quiet`
  - `scripts/plugin-local.sh ssh-flow`
  - `scripts/plugin-local.sh ssh-guards`
  - `scripts/plugin-local.sh ssh-all`

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
- Run `scripts/plugin-local.sh reference-status --check` to fail fast when the local reference source, fixtures, or guard scripts are missing, or when the installed reference path has drifted into a foreign symlink/non-symlink state.
- Run `scripts/plugin-local.sh reference-status --check --quiet` when you want the preflight result without printing the full dashboard.
- Run `scripts/plugin-local.sh reference-status --quiet` when you want a one-line local availability summary for the reference toolkit.
- Run `scripts/plugin-local.sh reference-files` when you need only the canonical fixture and guard paths.
- Run `scripts/plugin-local.sh reference-guards` when you need only the runnable reference guard commands in order.
- Run `scripts/plugin-local.sh reference-all` when you want to execute the full reference-only guard sequence without the rest of `plugin-verify.sh`.
- Run `scripts/plugin-local.sh reference-all --quiet` when you want the reference-only guard sequence without stage headings.
- Run `scripts/plugin-local.sh reference-all --quiet --silent-preflight` when you want the most compact successful reference-only run output.
- Run `scripts/plugin-local.sh shared-gates` when you want only the shared runtime and diagnostics tail checks.
- Run `scripts/plugin-local.sh shared-gates --quiet` when you want that shared tail without wrapper headings.
- Run `scripts/plugin-local.sh baseline-gates` when you want only the conformance and doctor-smoke entry gates.
- Run `scripts/plugin-local.sh baseline-gates --quiet` when you want that entry phase without wrapper headings.
- Run `scripts/plugin-local.sh all-gates` when you want the same assembled pipeline used by `plugin-verify.sh` and `plugin-local.sh full`.
- Run `scripts/plugin-local.sh all-gates --quiet` when you want that assembled pipeline without the phase headings.
- `scripts/plugin-local.sh all-gates` runs the Docker Manager guard sequence when `scripts/plugin-local.sh docker-status --check` succeeds, and otherwise skips that optional Docker-specific phase.
- `scripts/plugin-local.sh quick` reuses `reference-all --quiet --silent-preflight` before the shared runtime and diagnostics gates, so the fast path and the reference-only path stay aligned without extra preflight noise.
- Run `scripts/plugin-local.sh quick --quiet` when you want that same fast path without the top-level wrapper lines or shared-gate headings.

## Reference Plugin Workflow

- Install the repo-tracked reference plugin into a local plugin directory with `scripts/plugin-local.sh install-reference`.
- Validate the installed reference plugin in isolation with `scripts/plugin-local.sh smoke-reference`.
- Remove the linked reference plugin with `scripts/plugin-local.sh remove-reference`.
- `install-reference` is intentionally conservative: it is idempotent for the correct symlink target, but refuses to overwrite a non-symlink path or replace a symlink that points somewhere else.
- `smoke-reference` is intentionally strict: it validates the expected repo-tracked reference symlink and fails when the plugin path is not that symlink, when the symlink target is wrong, when the manifest is absent, or when the installed manifest id does not match `reference.local.toolkit`.
- `remove-reference` is safe to rerun when the reference plugin is already absent, but refuses to delete a non-symlink path or a symlink that points somewhere other than the repo-tracked reference plugin.
- Keep `scripts/check-plugin-reference-contracts.sh` green when changing the reference plugin so its intended manifest, state, launcher, and settings behaviors do not drift.
- Keep `scripts/check-plugin-reference-fixtures.sh` green when changing reference-plugin persistence so expected state-envelope and settings-key shapes do not drift.
- Keep `scripts/check-plugin-reference-recovery.sh` green when changing launcher failure handling so healthy, degraded, and recovery transitions remain aligned with `PluginService`.
- Keep `scripts/check-plugin-reference-diagnostics.sh` green when changing diagnostics export so the real reference plugin continues to produce stable active and degraded payload examples.
- `scripts/plugin-local.sh quick` is the fastest local way to catch reference-plugin and diagnostics/runtime contract drift together.
- Open launcher mode with `!ref` after installation to exercise increment, reset, and summary actions.
- Use the reference plugin settings page to toggle launcher failure modes (`query` or `execute`) and confirm degraded diagnostics in the Plugins tab.

## First-Party SSH Plugin Workflow

- Shipped plugin path: `config/plugins/ssh-monitor`
- Launcher trigger: `!ssh`
- Keep `scripts/check-plugin-ssh-local.sh` green when changing the shipped manifest or install shape.
- Keep `scripts/check-plugin-ssh-runtime-smoke.sh` green when changing runtime loading, ssh-config import behavior, or launcher/settings interactions.
- Keep `scripts/check-plugin-ssh-contracts.sh` green when changing the intended first-party manifest, launcher, settings, or command wiring contract.
- Keep `scripts/check-plugin-ssh-fixtures.sh` green when changing parser behavior or persisted settings/state envelope shapes.
- Run `scripts/plugin-local.sh ssh-status --check` for a fast preflight over the shipped plugin files, fixtures, and SSH-specific guard scripts.
- Run `scripts/plugin-local.sh ssh-status --check --quiet` when you want the compact one-line SSH preflight status.
- Run `scripts/plugin-local.sh ssh-flow` for the manual first-party SSH plugin validation sequence.
- Run `scripts/plugin-local.sh ssh-guards` for the canonical SSH-only guard command list.
- Run `scripts/plugin-local.sh ssh-all` for the SSH-only automated guard sequence.
- Run `scripts/plugin-local.sh shared-gates --quiet` for the shared plugin tail that now includes the first-party SSH checks.
- Run `scripts/plugin-verify.sh --quiet` for the full assembled plugin pipeline.
- Open launcher mode with `!ssh` to exercise connect and copy actions against the shipped plugin.

## Docker Manager Plugin Workflow

- Repo-tracked plugin path: `examples/plugins/docker-manager`
- Bar widget surface: `Docker Manager`
- Keep `scripts/check-plugin-docker-manager-local.sh` green when changing install shape, manifest wiring, or local command flow.
- Keep `scripts/check-plugin-docker-manager-runtime-smoke.sh` green when changing daemon refresh logic, settings reload behavior, or degraded-runtime handling.
- Keep `scripts/check-plugin-docker-manager-contracts.sh` green when changing the intended multi-plugin manifest, popup wiring, or settings contract.
- Run `scripts/plugin-local.sh docker-status --check` for a fast preflight over the shipped plugin files, required guard scripts, `quickshell`, and Docker availability.
- Run `scripts/plugin-local.sh docker-flow` for the manual Docker Manager validation sequence.
- Run `scripts/plugin-local.sh docker-all` for the Docker Manager-only automated guard sequence.
- `scripts/plugin-local.sh all-gates` and `scripts/plugin-verify.sh` include the Docker Manager guard sequence automatically when Docker Manager prerequisites are available on the machine.
- Install the repo-tracked plugin locally with `scripts/plugin-local.sh install-docker-manager`.
- Validate that local install in isolation with `scripts/plugin-local.sh smoke-docker-manager`.
- Remove the local symlink with `scripts/plugin-local.sh remove-docker-manager`.
- Add `Docker Manager` from the bar widget picker to exercise the popup against the local Docker daemon.

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
