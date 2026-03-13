# Shared Panel Plugin Manifest v2

Plugins are loaded from:

- `~/.config/quickshell/plugins/<plugin-id>/manifest.json`

Use `manifest-v2.schema.json` as the reference contract for plugin manifests.

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
