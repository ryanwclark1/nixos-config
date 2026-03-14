# Docker Manager

Optional Quickshell plugin for monitoring and managing Docker or Podman containers from the bar.

This is a clean-room Quickshell redevelopment inspired by the DMS Docker Manager plugin:

- upstream project: `https://github.com/LuckShiba/DmsDockerManager`
- implementation here does not reuse upstream QML or plugin APIs

What it provides:

- bar widget with runtime health and running-container count
- anchored popup with container and compose-project views
- start, stop, restart, pause, unpause, logs, and shell actions
- configurable runtime binary (`docker` or `podman`)
- settings for refresh, terminal command, shell path, port visibility, and popup behavior

Requirements:

- Docker or Podman accessible from the configured runtime binary
- user permission to run container commands
- terminal command capable of accepting a shell command argument

Manual local install:

1. Symlink or copy this directory into `~/.config/quickshell/plugins/docker-manager`.
2. Open Settings -> Plugins.
3. Enable `Docker Manager`.
4. Add `Docker Manager` from the bar widget picker.

Repo-local helpers:

- `scripts/plugin-local.sh install-docker-manager`
- `scripts/plugin-local.sh smoke-docker-manager`
- `scripts/plugin-local.sh docker-status --check`
- `scripts/plugin-local.sh docker-all`
- `scripts/plugin-local.sh remove-docker-manager`

Suggested defaults:

- runtime binary: `docker`
- terminal command: `kitty -e bash -lc`
- shell path: `/bin/sh`

Notes:

- Compose project grouping is inferred from Docker and Podman compose labels.
- The popup is self-contained inside the plugin and does not participate in `shell.qml` surface routing.
