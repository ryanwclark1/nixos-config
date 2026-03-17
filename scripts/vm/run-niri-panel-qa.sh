#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
launcher="${repo_root}/scripts/vm/launch-niri-test-vm.sh"
ssh_port="${NIRI_VM_QA_SSH_PORT:-2232}"
vm_password="${NIRI_VM_PASSWORD:-niri}"
boot_timeout="${NIRI_VM_QA_BOOT_TIMEOUT:-300}"
poll_attempts="${NIRI_VM_QA_POLL_ATTEMPTS:-120}"
poll_delay="${NIRI_VM_QA_POLL_DELAY:-2}"
output_dir="${NIRI_VM_QA_OUTPUT_DIR:-/tmp/panel-qa-matrix-niri-host}"
capture_mode="panel"
reset_disk=0
keep_vm_running=0
vm_output_dir=""
launcher_log="${NIRI_VM_QA_LOG:-/tmp/niri-test-vm-qa.log}"
extra_capture_args=()
host_pubkey_file=""

usage() {
  cat <<'EOF'
Usage: run-niri-panel-qa.sh [--output-dir DIR] [--mode panel|settings|surfaces]
                           [--ssh-port PORT] [--reset-disk] [--keep-vm-running]
                           [--vm-output-dir DIR] [-- <extra capture args>]

Boot a dedicated Niri VM, sync the panel repo subtree into the guest, run the
selected Quickshell capture flow inside the VM, and copy the resulting artifact
directory back to the host.

Modes:
  panel      Run capture-panel-matrix.sh --repo-shell --skip-launcher
  settings   Run capture-panel-matrix.sh --repo-shell --skip-surfaces --skip-launcher
  surfaces   Run capture-panel-matrix.sh --repo-shell --skip-settings --skip-launcher
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      output_dir="${2:-}"
      shift 2
      ;;
    --mode)
      capture_mode="${2:-}"
      shift 2
      ;;
    --ssh-port)
      ssh_port="${2:-}"
      shift 2
      ;;
    --reset-disk)
      reset_disk=1
      shift
      ;;
    --keep-vm-running)
      keep_vm_running=1
      shift
      ;;
    --vm-output-dir)
      vm_output_dir="${2:-}"
      shift 2
      ;;
    --)
      shift
      extra_capture_args=("$@")
      break
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${vm_output_dir}" ]]; then
  vm_output_dir="/tmp/panel-qa-${capture_mode}-$(date +%Y%m%d-%H%M%S)"
fi

mkdir -p "${output_dir}"

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
  -p "${ssh_port}"
  administrator@127.0.0.1
)

scp_base=(
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
  scp
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o PreferredAuthentications=password
  -o PubkeyAuthentication=no
  -o KbdInteractiveAuthentication=no
  -o NumberOfPasswordPrompts=1
  -o ControlMaster=no
  -o ControlPath=none
  -P "${ssh_port}"
)

cleanup() {
  if (( keep_vm_running == 0 )) && [[ -n "${launcher_pid:-}" ]] && kill -0 "${launcher_pid}" 2>/dev/null; then
    kill "${launcher_pid}" 2>/dev/null || true
    wait "${launcher_pid}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

wait_for_ssh() {
  local i
  for ((i = 1; i <= poll_attempts; i++)); do
    if "${ssh_base[@]}" "echo READY" >/dev/null 2>&1; then
      return 0
    fi
    if [[ -n "${launcher_pid:-}" ]] && ! kill -0 "${launcher_pid}" 2>/dev/null; then
      echo "[ERROR] VM launcher exited before SSH became ready" >&2
      tail -n 120 "${launcher_log}" >&2 || true
      return 1
    fi
    sleep "${poll_delay}"
  done
  echo "[ERROR] Timed out waiting for SSH on port ${ssh_port}" >&2
  tail -n 120 "${launcher_log}" >&2 || true
  return 1
}

install_host_pubkey() {
  local pubkey=""

  resolve_host_pubkey || return 0
  pubkey="$(<"${host_pubkey_file}")"
  [[ -n "${pubkey}" ]] || return 0

  "${ssh_base[@]}" "umask 077 && mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys && grep -qxF $(printf '%q' "${pubkey}") ~/.ssh/authorized_keys || printf '%s\n' $(printf '%q' "${pubkey}") >> ~/.ssh/authorized_keys"
}

wait_for_niri() {
  local i
  if ! "${ssh_base[@]}" '
    if pgrep -fa "niri --session" >/dev/null 2>&1; then
      exit 0
    fi
    systemctl --user stop quickshell.service quickshell-health.service graphical-session.target >/dev/null 2>&1 || true
    nohup sh -lc "exec uwsm start niri.desktop >/tmp/uwsm-niri.log 2>&1" >/dev/null 2>&1 &
  ' >/dev/null 2>&1; then
    echo "[ERROR] Failed to request Niri startup inside the VM" >&2
    return 1
  fi

  for ((i = 1; i <= 60; i++)); do
    if "${ssh_base[@]}" '
      pgrep -fa "niri --session" >/dev/null 2>&1 &&
      systemctl --user show-environment 2>/dev/null | grep -q "^NIRI_SOCKET=" &&
      systemctl --user show-environment 2>/dev/null | grep -q "^WAYLAND_DISPLAY="
    ' >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done

  echo "[ERROR] Expected Niri session to be running in the VM" >&2
  "${ssh_base[@]}" '
    echo "--- processes ---"
    pgrep -a "niri|quickshell|kitty|uwsm|sddm" || true
    echo "--- uwsm log ---"
    sed -n "1,160p" /tmp/uwsm-niri.log 2>/dev/null || true
    echo "--- env ---"
    systemctl --user show-environment 2>/dev/null | grep -E "NIRI|WAYLAND|XDG_CURRENT_DESKTOP|DESKTOP_SESSION|XDG_SESSION_TYPE" || true
    echo "--- session ---"
    loginctl show-session "$XDG_SESSION_ID" -p Name -p Desktop -p Type 2>/dev/null || true
    echo "--- user journal ---"
    journalctl --user --no-pager -n 120 2>/dev/null || true
    echo "--- login journal ---"
    journalctl --no-pager -b -n 120 2>/dev/null | grep -E "getty|login|niri|quickshell|zsh" || true
  ' >&2
  return 1
}

sync_repo() {
  local remote_repo="$1"
  local panel_rel="home/features/desktop/window-managers/shared/panel"
  local remote_panel_parent="${remote_repo}/home/features/desktop/window-managers/shared"

  echo "[INFO] Syncing repo checkout into VM: ${remote_repo}"
  "${ssh_base[@]}" "rm -rf '${remote_repo}' && mkdir -p '${remote_panel_parent}'"
  tar -C "${repo_root}" -cf - "${panel_rel}" | "${ssh_base[@]}" "tar -xf - -C '${remote_repo}'"
}

run_remote_capture() {
  local remote_repo="$1"
  local remote_panel_root="${remote_repo}/home/features/desktop/window-managers/shared/panel/quickshell"
  local remote_cmd=""
  local extra=""
  local arg

  case "${capture_mode}" in
    panel)
      remote_cmd="bash '${remote_panel_root}/scripts/capture-panel-matrix.sh' --repo-shell --skip-launcher --output-dir '${vm_output_dir}'"
      ;;
    settings)
      remote_cmd="bash '${remote_panel_root}/scripts/capture-panel-matrix.sh' --repo-shell --skip-surfaces --skip-launcher --output-dir '${vm_output_dir}'"
      ;;
    surfaces)
      remote_cmd="bash '${remote_panel_root}/scripts/capture-panel-matrix.sh' --repo-shell --skip-settings --skip-launcher --output-dir '${vm_output_dir}'"
      ;;
    *)
      printf 'Unknown mode: %s\n' "${capture_mode}" >&2
      exit 2
      ;;
  esac

  if (( ${#extra_capture_args[@]} > 0 )); then
    for arg in "${extra_capture_args[@]}"; do
      extra+=" $(printf '%q' "${arg}")"
    done
    remote_cmd+="${extra}"
  fi

  echo "[INFO] Running capture mode '${capture_mode}' in VM"
  "${ssh_base[@]}" "${remote_cmd}"
}

copy_artifacts_home() {
  echo "[INFO] Copying artifacts back to host: ${output_dir}"
  rm -rf "${output_dir}"
  mkdir -p "${output_dir}"
  "${scp_base[@]}" -r "administrator@127.0.0.1:${vm_output_dir}/." "${output_dir}/"
}

echo "[INFO] Launching Niri test VM on SSH port ${ssh_port}"
: > "${launcher_log}"
launcher_args=(--ssh-port "${ssh_port}")
if (( reset_disk == 1 )); then
  launcher_args+=(--reset-disk)
fi
coproc VM_LAUNCHER {
  exec bash "${launcher}" "${launcher_args[@]}" >"${launcher_log}" 2>&1
}
launcher_pid="${VM_LAUNCHER_PID}"

wait_for_ssh
install_host_pubkey
wait_for_niri

run_id="$(date +%Y%m%d-%H%M%S)-$$"
remote_repo="/tmp/nixos-config-${run_id}"
sync_repo "${remote_repo}"
run_remote_capture "${remote_repo}"
copy_artifacts_home

echo "[INFO] Host review artifacts saved to ${output_dir}"
if (( keep_vm_running == 1 )); then
  echo "[INFO] VM left running on SSH port ${ssh_port}"
fi
