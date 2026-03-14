# Reference Local Toolkit

Local-only reference plugin for validating the QuickShell plugin system end-to-end.

What it covers:

- bar widget rendering
- launcher provider items and execution
- settings read/write flows
- state envelope persistence
- controlled degraded diagnostics via launcher failure modes

Local workflow:

- `scripts/plugin-local.sh install-reference`
- `scripts/plugin-local.sh smoke-reference`
- `scripts/plugin-local.sh remove-reference`

Behavior:

- Bar widget increments a shared counter on click.
- Launcher trigger is `!ref`.
- Settings page can cycle label, toggle the updated marker, and force `query` or `execute` launcher failures.
