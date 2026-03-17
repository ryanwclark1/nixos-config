#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
port="${NIRI_VM_SMOKE_SSH_PORT:-2232}"
poll_attempts="${NIRI_VM_SMOKE_POLL_ATTEMPTS:-120}"
poll_delay="${NIRI_VM_SMOKE_POLL_DELAY:-2}"
launcher="${repo_root}/scripts/vm/launch-niri-test-vm.sh"
log_file="${NIRI_VM_SMOKE_LOG:-/tmp/niri-test-vm-smoke.log}"
vm_password="${NIRI_VM_PASSWORD:-niri}"
host_pubkey_file=""

cleanup() {
  if [[ -n "${launcher_pid:-}" ]] && kill -0 "${launcher_pid}" 2>/dev/null; then
    kill "${launcher_pid}" 2>/dev/null || true
    wait "${launcher_pid}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

resolve_host_pubkey() {
  local candidate=""
  for candidate in \
    "${HOME}/.ssh/id_ed25519.pub" \
    "${HOME}/.ssh/id_rsa.pub"
  do
    if [[ -r "${candidate}" ]]; then
      host_pubkey_file="${candidate}"
      return 0
    fi
  done
  return 1
}

ssh_base=(
  nix
  shell
  nixpkgs#sshpass
  -c
  env
  SSH_ASKPASS=
  SSH_ASKPASS_REQUIRE=never
  DISPLAY=
  SSHPASS="${vm_password}"
  sshpass
  -e
  ssh
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o ConnectTimeout=5
  -o PreferredAuthentications=password
  -o PubkeyAuthentication=no
  -o KbdInteractiveAuthentication=no
  -o NumberOfPasswordPrompts=1
  -o ControlMaster=no
  -o ControlPath=none
  -p "${port}"
  administrator@127.0.0.1
)

install_host_pubkey() {
  local pubkey=""

  resolve_host_pubkey || return 0
  pubkey="$(<"${host_pubkey_file}")"
  [[ -n "${pubkey}" ]] || return 0

  "${ssh_base[@]}" "umask 077 && mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && grep -qxF $(printf '%q' "${pubkey}") ~/.ssh/authorized_keys || printf '%s\n' $(printf '%q' "${pubkey}") >> ~/.ssh/authorized_keys"
}

echo "[INFO] Launching smoke VM on SSH port ${port}"
: > "${log_file}"
coproc VM_LAUNCHER {
  exec bash "${launcher}" --reset-disk --ssh-port "${port}" >"${log_file}" 2>&1
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

install_host_pubkey

echo "[INFO] SSH is ready; validating session"

for ((i = 1; i <= 30; i++)); do
  if "${ssh_base[@]}" '
    pgrep -fa "niri --session" >/dev/null &&
    pgrep -fa "/quickshell" >/dev/null &&
    pgrep -fa "kitty" >/dev/null
  '; then
    break
  fi
  sleep 2
done

if ! "${ssh_base[@]}" '
  pgrep -fa "niri --session" >/dev/null &&
  pgrep -fa "/quickshell" >/dev/null &&
  pgrep -fa "kitty" >/dev/null
'; then
  echo "[ERROR] Expected niri/quickshell/kitty to be running" >&2
  "${ssh_base[@]}" 'pgrep -a "niri|quickshell|kitty|waybar|voxtype|blueman|nm-applet|syncthing|polkit|geoclue" || true' >&2
  exit 1
fi

if "${ssh_base[@]}" '
  pgrep -x waybar >/dev/null ||
  pgrep -x voxtype >/dev/null ||
  pgrep -x blueman-applet >/dev/null ||
  pgrep -x nm-applet >/dev/null ||
  pgrep -x syncthing >/dev/null ||
  systemctl --user --quiet is-active niri-flake-polkit.service ||
  systemctl --user --quiet is-active geoclue-agent.service
'; then
  echo "[ERROR] Unexpected applet/background processes are still running" >&2
  "${ssh_base[@]}" '
    for proc in waybar voxtype blueman-applet nm-applet syncthing geoclue-agent; do
      pgrep -a -x "$proc" || true
    done
    systemctl --user status --no-pager niri-flake-polkit.service geoclue-agent.service 2>/dev/null || true
  ' >&2
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

desktop_name="$("${ssh_base[@]}" 'loginctl show-session "$XDG_SESSION_ID" -p Desktop --value 2>/dev/null || true')"
session_type="$("${ssh_base[@]}" 'loginctl show-session "$XDG_SESSION_ID" -p Type --value 2>/dev/null || true')"

if [[ -n "${desktop_name}" && "${desktop_name}" != "niri" ]]; then
  echo "[WARN] Desktop session reports '${desktop_name}' instead of 'niri'" >&2
fi

if [[ -n "${session_type}" && "${session_type}" != "tty" && "${session_type}" != "wayland" ]]; then
  echo "[WARN] Unexpected session type '${session_type}'" >&2
fi

echo "[INFO] Smoke check passed"
