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
- Plugin runtime guard gate:
  - `scripts/check-plugin-runtime-guards.sh`
- Plugin diagnostics contract gate:
  - `scripts/check-plugin-diagnostics-contracts.sh`
- Plugin diagnostics schema gate (ajv):
  - `scripts/check-plugin-diagnostics-schema.sh`
  - requires `ajv` or `npx` (`nodejs`)
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
