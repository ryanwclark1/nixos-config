#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." >/dev/null 2>&1 && pwd -P)"
port="${NIRI_VM_SMOKE_SSH_PORT:-2232}"
boot_timeout="${NIRI_VM_SMOKE_BOOT_TIMEOUT:-300}"
poll_delay="${NIRI_VM_SMOKE_POLL_DELAY:-2}"
poll_attempts="${NIRI_VM_SMOKE_POLL_ATTEMPTS:-}"
niri_unit_timeout="${NIRI_VM_SMOKE_NIRI_UNIT_TIMEOUT:-120}"
niri_session_timeout="${NIRI_VM_SMOKE_SESSION_TIMEOUT:-120}"
launcher="${repo_root}/scripts/vm/launch-niri-test-vm.sh"
log_file="${NIRI_VM_SMOKE_LOG:-/tmp/niri-test-vm-smoke.log}"
vm_password="${NIRI_VM_PASSWORD:-niri}"
ssh_identity_file="${NIRI_VM_SSH_IDENTITY:-}"
host_pubkey_file=""
use_key_auth=0

if [[ -z "${poll_attempts}" ]]; then
  poll_attempts=$(( (boot_timeout + poll_delay - 1) / poll_delay ))
fi

cleanup() {
  if [[ -n "${launcher_pid:-}" ]] && kill -0 "${launcher_pid}" 2>/dev/null; then
    kill "${launcher_pid}" 2>/dev/null || true
    wait "${launcher_pid}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

resolve_host_identity() {
  local candidate=""

  if [[ -n "${ssh_identity_file}" ]]; then
    [[ -r "${ssh_identity_file}" ]] || return 1
    return 0
  fi

  candidate="${HOME}/.ssh/id_rsa"
  if [[ -r "${candidate}" ]]; then
    ssh_identity_file="${candidate}"
    return 0
  fi

  return 1
}

resolve_host_pubkey() {
  local candidate=""

  if resolve_host_identity; then
    candidate="${ssh_identity_file}.pub"
    if [[ -r "${candidate}" ]]; then
      host_pubkey_file="${candidate}"
      return 0
    fi
  fi

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

ssh_common_opts=(
  -o LogLevel=ERROR
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o ConnectTimeout=5
  -o KbdInteractiveAuthentication=no
  -o NumberOfPasswordPrompts=1
  -o ControlMaster=no
  -o ControlPath=none
)

if resolve_host_identity; then
  use_key_auth=1
  ssh_key_base=(
    ssh
    "${ssh_common_opts[@]}"
    -o PreferredAuthentications=publickey
    -o PubkeyAuthentication=yes
    -o PasswordAuthentication=no
    -o IdentitiesOnly=yes
    -i "${ssh_identity_file}"
    -p "${port}"
    administrator@127.0.0.1
  )
fi

ssh_password_base=(
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
  "${ssh_common_opts[@]}"
  -o PreferredAuthentications=password
  -o PubkeyAuthentication=no
  -p "${port}"
  administrator@127.0.0.1
)

vm_ssh() {
  if (( use_key_auth == 1 )) && "${ssh_key_base[@]}" "$@"; then
    return 0
  fi

  "${ssh_password_base[@]}" "$@"
}

wait_for_niri_unit() {
  local deadline=$((SECONDS + niri_unit_timeout))

  while (( SECONDS < deadline )); do
    if vm_ssh '
      loginctl list-sessions --no-legend 2>/dev/null | grep -Eq "tty1|ttyS0" &&
      systemctl --user list-unit-files --no-legend niri.service 2>/dev/null | grep -qE "^niri\\.service[[:space:]]"
    ' >/dev/null 2>&1; then
      return 0
    fi

    sleep 2
  done
  return 1
}

ensure_niri_running() {
  local deadline=$((SECONDS + niri_session_timeout))

  while (( SECONDS < deadline )); do
    if vm_ssh 'pgrep -fa "niri --session" >/dev/null 2>&1'; then
      return 0
    fi

    vm_ssh '
      systemctl --user reset-failed niri.service >/dev/null 2>&1 || true
      timeout 15s systemctl --user start niri.service >/dev/null 2>&1 || true
    ' >/dev/null 2>&1 || true
    sleep 2
  done

  return 1
}

install_host_pubkey() {
  local pubkey=""

  resolve_host_pubkey || return 0
  pubkey="$(<"${host_pubkey_file}")"
  [[ -n "${pubkey}" ]] || return 0

  vm_ssh "umask 077 && mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && grep -qxF $(printf '%q' "${pubkey}") ~/.ssh/authorized_keys || printf '%s\n' $(printf '%q' "${pubkey}") >> ~/.ssh/authorized_keys"
}

echo "[INFO] Launching smoke VM on SSH port ${port}"
if (( use_key_auth == 1 )); then
  echo "[INFO] Using SSH identity ${ssh_identity_file} for Niri VM access"
else
  echo "[INFO] Using password-based SSH fallback for Niri VM access"
fi
: > "${log_file}"
coproc VM_LAUNCHER {
  exec bash "${launcher}" --reset-disk --ssh-port "${port}" >"${log_file}" 2>&1
}
launcher_pid="${VM_LAUNCHER_PID}"

for ((i = 1; i <= poll_attempts; i++)); do
  if vm_ssh "echo READY" >/dev/null 2>&1; then
    break
  fi
  if ! kill -0 "${launcher_pid}" 2>/dev/null; then
    echo "[ERROR] VM launcher exited before SSH became ready" >&2
    tail -n 120 "${log_file}" >&2 || true
    exit 1
  fi
  sleep "${poll_delay}"
done

if ! vm_ssh "echo READY" >/dev/null 2>&1; then
  echo "[ERROR] Timed out waiting for SSH on port ${port}" >&2
  tail -n 120 "${log_file}" >&2 || true
  exit 1
fi

install_host_pubkey

echo "[INFO] SSH is ready; validating session"

if ! wait_for_niri_unit; then
  echo "[ERROR] Timed out waiting for niri.service to be registered in the user manager" >&2
  vm_ssh '
    echo "--- sessions ---"
    loginctl list-sessions --no-legend || true
    echo "--- user units ---"
    systemctl --user list-unit-files "niri*" || true
  ' >&2 || true
  exit 1
fi

if ! ensure_niri_running; then
  echo "[ERROR] Failed to start niri.service inside the VM" >&2
  vm_ssh '
    systemctl --user status --no-pager niri.service 2>/dev/null || true
    journalctl --user --no-pager -u niri.service -n 120 2>/dev/null || true
  ' >&2 || true
  exit 1
fi

for ((i = 1; i <= 30; i++)); do
  if vm_ssh '
    pgrep -fa "niri --session" >/dev/null &&
    pgrep -fa "/quickshell" >/dev/null &&
    pgrep -fa "kitty" >/dev/null
  '; then
    break
  fi
  sleep 2
done

if ! vm_ssh '
  pgrep -fa "niri --session" >/dev/null &&
  pgrep -fa "/quickshell" >/dev/null &&
  pgrep -fa "kitty" >/dev/null
'; then
  echo "[ERROR] Expected niri/quickshell/kitty to be running" >&2
  vm_ssh 'pgrep -a "niri|quickshell|kitty|waybar|voxtype|blueman|nm-applet|syncthing|polkit|geoclue" || true' >&2
  exit 1
fi

if vm_ssh '
  pgrep -x waybar >/dev/null ||
  pgrep -x voxtype >/dev/null ||
  pgrep -x blueman-applet >/dev/null ||
  pgrep -x nm-applet >/dev/null ||
  pgrep -x syncthing >/dev/null ||
  systemctl --user --quiet is-active niri-flake-polkit.service ||
  systemctl --user --quiet is-active geoclue-agent.service
'; then
  echo "[ERROR] Unexpected applet/background processes are still running" >&2
  vm_ssh '
    for proc in waybar voxtype blueman-applet nm-applet syncthing geoclue-agent; do
      pgrep -a -x "$proc" || true
    done
    systemctl --user status --no-pager niri-flake-polkit.service geoclue-agent.service 2>/dev/null || true
  ' >&2
  exit 1
fi

echo "[INFO] Session summary:"
vm_ssh '
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

desktop_name="$(vm_ssh 'loginctl show-session "$XDG_SESSION_ID" -p Desktop --value 2>/dev/null || true')"
session_type="$(vm_ssh 'loginctl show-session "$XDG_SESSION_ID" -p Type --value 2>/dev/null || true')"

if [[ -n "${desktop_name}" && "${desktop_name}" != "niri" ]]; then
  echo "[WARN] Desktop session reports '${desktop_name}' instead of 'niri'" >&2
fi

if [[ -n "${session_type}" && "${session_type}" != "tty" && "${session_type}" != "wayland" ]]; then
  echo "[WARN] Unexpected session type '${session_type}'" >&2
fi

echo "[INFO] Smoke check passed"
