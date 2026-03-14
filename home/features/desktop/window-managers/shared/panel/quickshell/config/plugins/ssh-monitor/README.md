# SSH Monitor

First-party SSH plugin for the shared Quickshell panel.

What it covers:

- bar widget with total-host or recent-host summary
- launcher provider with `!ssh` trigger
- manual host management in plugin settings
- `~/.ssh/config` import with `Include` support and wildcard skipping
- launcher connect and copy actions backed by the existing plugin process API

Behavior:

- Manual hosts override imported aliases when their normalized ids match.
- Imported aliases execute as `ssh <alias>` so OpenSSH keeps handling final config resolution.
- Copy actions send the display command to `wl-copy`.
- Connect actions launch through `kitty -e bash -lc`.

Local verification:

- `scripts/check-plugin-ssh-local.sh`
- `scripts/check-plugin-ssh-runtime-smoke.sh`
- `scripts/check-plugin-ssh-contracts.sh`
- `scripts/check-plugin-ssh-fixtures.sh`
- `scripts/plugin-local.sh ssh-status`
- `scripts/plugin-local.sh ssh-status --check --quiet`
- `scripts/plugin-local.sh ssh-flow`
- `scripts/plugin-local.sh ssh-guards`
- `scripts/plugin-local.sh ssh-all`
- `scripts/plugin-local.sh shared-gates`
- `scripts/plugin-verify.sh --quiet`
