set -euo pipefail

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
state_file="${state_dir}/hyprland.json"

mkdir -p "${state_dir}"

monitors_json="$(hyprctl -j monitors 2>/dev/null || echo '[]')"
workspaces_json="$(hyprctl -j workspaces 2>/dev/null || echo '[]')"
active_window_json="$(hyprctl -j activewindow 2>/dev/null || echo '{}')"
devices_json="$(hyprctl -j devices 2>/dev/null || echo '{}')"
clients_json="$(hyprctl -j clients 2>/dev/null || echo '[]')"

jq -n \
  --argjson monitors "${monitors_json}" \
  --argjson workspaces "${workspaces_json}" \
  --argjson activewindow "${active_window_json}" \
  --argjson devices "${devices_json}" \
  --argjson clients "${clients_json}" \
  '{
    activeWorkspace: ($monitors | map(select(.focused == true)) | .[0].activeWorkspace.id // 0),
    specialWorkspace: ($monitors | map(select(.focused == true)) | .[0].specialWorkspace.name // ""),
    workspaces: ($workspaces | sort_by(.id) | map({id, name, windows, monitor})),
    windowTitle: ($activewindow.title // ""),
    keyboardLayout: ($devices.keyboards // [] | map(select(.main == true)) | .[0].active_keymap // ""),
    clients: ($clients | map(select(.workspace.id != -1)) | map({address, title, class, workspace: .workspace.id, monitor}))
  }' > "${state_file}.tmp"

mv "${state_file}.tmp" "${state_file}"
