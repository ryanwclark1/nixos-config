#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
port="${NIRI_VM_SMOKE_SSH_PORT:-2232}"
boot_timeout="${NIRI_VM_SMOKE_BOOT_TIMEOUT:-300}"
poll_attempts="${NIRI_VM_SMOKE_POLL_ATTEMPTS:-120}"
poll_delay="${NIRI_VM_SMOKE_POLL_DELAY:-2}"
launcher="${repo_root}/scripts/vm/launch-niri-test-vm.sh"
log_file="${NIRI_VM_SMOKE_LOG:-/tmp/niri-test-vm-smoke.log}"

cleanup() {
  if [[ -n "${launcher_pid:-}" ]] && kill -0 "${launcher_pid}" 2>/dev/null; then
    kill "${launcher_pid}" 2>/dev/null || true
    wait "${launcher_pid}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

ssh_base=(
  ssh
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o ConnectTimeout=5
  -p "${port}"
  administrator@127.0.0.1
)

echo "[INFO] Launching smoke VM on SSH port ${port}"
: > "${log_file}"
coproc VM_LAUNCHER {
  exec timeout "${boot_timeout}" bash "${launcher}" --reset-disk --ssh-port "${port}" >"${log_file}" 2>&1
}
launcher_pid="${VM_LAUNCHER_PID}"

for ((i = 1; i <= poll_attempts; i++)); do
  if "${ssh_base[@]}" "echo READY" >/dev/null 2>&1; then
    break
  fi
  if ! kill -0 "${launcher_pid}" 2>/dev/null; then
    echo "[ERROR] VM launcher exited before SSH became ready" >&2
    tail -n 120 "${log_file}" >&2 || true
    exit 1
  fi
  sleep "${poll_delay}"
done

if ! "${ssh_base[@]}" "echo READY" >/dev/null 2>&1; then
  echo "[ERROR] Timed out waiting for SSH on port ${port}" >&2
  tail -n 120 "${log_file}" >&2 || true
  exit 1
fi

echo "[INFO] SSH is ready; validating session"

read -r expected_count unexpected_count desktop_name session_type <<<"$(
  "${ssh_base[@]}" '
    expected=$(pgrep -fc "niri --session|quickshell|kitty")
    unexpected=$(pgrep -fc "waybar|voxtype|blueman-applet|nm-applet|syncthing|polkit-kde-authentication-agent-1|geoclue-agent")
    desktop="$(loginctl show-session "$XDG_SESSION_ID" -p Desktop --value 2>/dev/null || true)"
    type="$(loginctl show-session "$XDG_SESSION_ID" -p Type --value 2>/dev/null || true)"
    printf "%s %s %s %s\n" "$expected" "$unexpected" "${desktop:-_}" "${type:-_}"
  '
)"

if (( expected_count < 3 )); then
  echo "[ERROR] Expected niri/quickshell/kitty to be running, saw count=${expected_count}" >&2
  "${ssh_base[@]}" 'pgrep -a "niri|quickshell|kitty|waybar|voxtype|blueman|nm-applet|syncthing|polkit|geoclue" || true' >&2
  exit 1
fi

if (( unexpected_count != 0 )); then
  echo "[ERROR] Unexpected applet/background processes are still running" >&2
  "${ssh_base[@]}" 'pgrep -a "waybar|voxtype|blueman-applet|nm-applet|syncthing|polkit-kde-authentication-agent-1|geoclue-agent" || true' >&2
  exit 1
fi

echo "[INFO] Session summary:"
"${ssh_base[@]}" '
  echo "Processes:"
  pgrep -a "niri|quickshell|kitty" || true
  echo
  echo "Failed user units:"
  systemctl --user --failed --no-legend || true
  echo
  echo "Session:"
  loginctl show-session "$XDG_SESSION_ID" -p Name -p Desktop -p Type || true
  echo
  echo "Recent user journal:"
  journalctl --user --no-pager -n 20
'

if [[ "${desktop_name}" != "_" && "${desktop_name}" != "niri" ]]; then
  echo "[WARN] Desktop session reports '${desktop_name}' instead of 'niri'" >&2
fi

if [[ "${session_type}" != "_" && "${session_type}" != "tty" && "${session_type}" != "wayland" ]]; then
  echo "[WARN] Unexpected session type '${session_type}'" >&2
fi

echo "[INFO] Smoke check passed"
