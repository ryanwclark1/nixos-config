# Docker Manager

Optional Quickshell plugin for monitoring and managing Docker or Podman containers from the bar.

This is a clean-room Quickshell redevelopment inspired by the DMS Docker Manager plugin:

- upstream project: `https://github.com/LuckShiba/DmsDockerManager`
- implementation here does not reuse upstream QML or plugin APIs

What it provides:

- bar widget with runtime health and running-container count
- anchored popup with five tabs: Containers, Compose, Images, Volumes, Networks
- container actions: start, stop, restart, pause, unpause, logs, and shell
- container health status indicators (green/yellow/red dots for healthy/starting/unhealthy)
- image management: list with in-use badges, run image dialog with port heuristics, remove unused
- volume management: list with driver info, remove individual or prune unused
- network management: list with driver/scope, default network protection, prune unused
- system prune with confirmation safety (double-click required by default)
- run image dialog with automatic port detection for common images (nginx, postgres, redis, etc.)
- configurable runtime binary (`docker` or `podman`)
- settings for refresh, terminal command, shell path, port visibility, tab visibility, and prune confirmation

Requirements:

- Docker or Podman accessible from the configured runtime binary
- `jq` for aggregating line-delimited JSON from resource listing commands
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
- `scripts/check-plugin-docker-manager-diagnostics.sh`
- `scripts/plugin-local.sh remove-docker-manager`

Suggested defaults:

- runtime binary: `docker`
- terminal command: `kitty -e bash -lc`
- shell path: `/bin/sh`

Settings keys:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `dockerBinary` | string | `"auto"` | Runtime binary path |
| `debounceDelay` | int | `300` | Event debounce in ms |
| `fallbackRefreshInterval` | int | `30000` | Fallback poll interval in ms |
| `terminalCommand` | string | `"auto"` | Terminal emulator command |
| `shellPath` | string | `"/bin/sh"` | Shell for container exec |
| `showPorts` | bool | `true` | Show port mappings |
| `autoScrollOnExpand` | bool | `true` | Auto-scroll on row expand |
| `groupByCompose` | bool | `false` | Default to compose view |
| `showImages` | bool | `true` | Show Images tab |
| `showVolumes` | bool | `true` | Show Volumes tab |
| `showNetworks` | bool | `true` | Show Networks tab |
| `confirmPrune` | bool | `true` | Require confirmation for prune |

Notes:

- Compose project grouping is inferred from Docker and Podman compose labels.
- The popup is self-contained inside the plugin and does not participate in `shell.qml` surface routing.
- Images, volumes, and networks are fetched alongside containers in a single refresh cycle.
- Port heuristics cover common images (nginx, postgres, mysql, redis, mongo, grafana, etc.) with 8080 as fallback.
