#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
launcher="${repo_root}/scripts/vm/launch-hyprland-test-vm.sh"
ssh_port="${HYPRLAND_VM_QA_SSH_PORT:-2242}"
vm_password="${HYPRLAND_VM_PASSWORD:-hyprland}"
qa_qemu_opts="${HYPRLAND_VM_QA_QEMU_OPTS:--vga none -device virtio-vga -display vnc=127.0.0.1:42}"
boot_timeout="${HYPRLAND_VM_QA_BOOT_TIMEOUT:-300}"
poll_attempts="${HYPRLAND_VM_QA_POLL_ATTEMPTS:-120}"
poll_delay="${HYPRLAND_VM_QA_POLL_DELAY:-2}"
output_dir="${HYPRLAND_VM_QA_OUTPUT_DIR:-/tmp/panel-qa-matrix-host}"
capture_mode="panel"
reset_disk=0
keep_vm_running=0
vm_output_dir=""
launcher_log="${HYPRLAND_VM_QA_LOG:-/tmp/hyprland-test-vm-qa.log}"
extra_capture_args=()

usage() {
  cat <<'EOF'
Usage: run-hyprland-panel-qa.sh [--output-dir DIR] [--mode panel|settings|surfaces|launcher]
                                [--ssh-port PORT] [--reset-disk] [--keep-vm-running]
                                [--vm-output-dir DIR] [-- <extra capture args>]

Boot a dedicated Hyprland VM, sync the repo checkout into the guest, run the
selected Quickshell capture flow inside the VM, and copy the resulting artifact
directory back to the host.

Modes:
  panel      Run capture-panel-matrix.sh --repo-shell
  settings   Run capture-panel-matrix.sh --repo-shell --skip-surfaces
  surfaces   Run capture-panel-matrix.sh --repo-shell --skip-settings
  launcher   Run capture-launcher-matrix.sh after launching the repo shell in the VM
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

wait_for_hyprland() {
  local i
  if ! "${ssh_base[@]}" '
    if pgrep -af "Hyprland" >/dev/null 2>&1; then
      exit 0
    fi
    systemctl --user stop quickshell.service quickshell-health.service graphical-session.target >/dev/null 2>&1 || true
    nohup sh -lc "exec uwsm start hyprland-uwsm.desktop >/tmp/uwsm-hyprland.log 2>&1" >/dev/null 2>&1 &
  ' >/dev/null 2>&1; then
    echo "[ERROR] Failed to request Hyprland startup inside the VM" >&2
    return 1
  fi

  for ((i = 1; i <= 60; i++)); do
    if "${ssh_base[@]}" '
      pgrep -af "Hyprland" >/dev/null 2>&1 &&
      systemctl --user show-environment 2>/dev/null | grep -q "^HYPRLAND_INSTANCE_SIGNATURE=" &&
      systemctl --user show-environment 2>/dev/null | grep -q "^WAYLAND_DISPLAY="
    ' >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done

  echo "[ERROR] Expected Hyprland to be running in the VM" >&2
  "${ssh_base[@]}" '
    echo "--- processes ---"
    pgrep -a "Hyprland|quickshell|kitty|uwsm|sddm|lightdm" || true
    echo "--- uwsm log ---"
    sed -n "1,160p" /tmp/uwsm-hyprland.log 2>/dev/null || true
    echo "--- env ---"
    systemctl --user show-environment 2>/dev/null | grep -E "HYPRLAND|WAYLAND|XDG_CURRENT_DESKTOP|DESKTOP_SESSION" || true
  ' >&2
  return 1
}

sync_repo() {
  local remote_repo="$1"
  echo "[INFO] Syncing repo checkout into VM: ${remote_repo}"
  "${ssh_base[@]}" "rm -rf '${remote_repo}' && mkdir -p '${remote_repo}'"
  tar \
    --exclude='./result' \
    --exclude='./.git' \
    --exclude='./tmp' \
    -C "${repo_root}" \
    -cf - . | "${ssh_base[@]}" "tar -xf - -C '${remote_repo}'"
}

run_remote_capture() {
  local remote_repo="$1"
  local remote_panel_root="${remote_repo}/home/features/desktop/window-managers/shared/panel/quickshell"
  local remote_cmd=""

  case "${capture_mode}" in
    panel)
      remote_cmd="bash '${remote_panel_root}/scripts/capture-panel-matrix.sh' --repo-shell --output-dir '${vm_output_dir}'"
      ;;
    settings)
      remote_cmd="bash '${remote_panel_root}/scripts/capture-panel-matrix.sh' --repo-shell --skip-surfaces --output-dir '${vm_output_dir}'"
      ;;
    surfaces)
      remote_cmd="bash '${remote_panel_root}/scripts/capture-panel-matrix.sh' --repo-shell --skip-settings --output-dir '${vm_output_dir}'"
      ;;
    launcher)
      "${ssh_base[@]}" "REMOTE_PANEL_ROOT='${remote_panel_root}' VM_OUTPUT_DIR='${vm_output_dir}' bash -s" <<'EOF'
set -euo pipefail

repo_shell_pid=""
service_was_active=0

cleanup() {
  if [[ -n "${repo_shell_pid}" ]]; then
    kill "${repo_shell_pid}" >/dev/null 2>&1 || true
    wait "${repo_shell_pid}" >/dev/null 2>&1 || true
  fi
  if (( service_was_active == 1 )); then
    systemctl --user start quickshell.service >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

if systemctl --user is-active --quiet quickshell.service; then
  service_was_active=1
  systemctl --user stop quickshell.service >/dev/null 2>&1 || true
  sleep 1
fi

mkdir -p "${VM_OUTPUT_DIR}"
env HYPRLAND_INSTANCE_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-}" \
  WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-}" \
  XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-}" \
  DESKTOP_SESSION="${DESKTOP_SESSION:-}" \
  quickshell -p "${REMOTE_PANEL_ROOT}/config/shell.qml" >/tmp/quickshell-repo-launcher-qa.log 2>&1 &
repo_shell_pid="$!"

for _ in $(seq 1 40); do
  if quickshell ipc --pid "${repo_shell_pid}" show >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done

for capture in \
  "drun home '' ${VM_OUTPUT_DIR}/drun-home.png" \
  "drun query firefox ${VM_OUTPUT_DIR}/drun-query.png" \
  "drun category Utility ${VM_OUTPUT_DIR}/drun-category.png" \
  "files empty __launcher_empty_probe__ ${VM_OUTPUT_DIR}/files-empty.png" \
  "system home '' ${VM_OUTPUT_DIR}/system-home.png"
do
  # shellcheck disable=SC2086
  set -- ${capture}
  mode="$1"
  state="$2"
  query="$3"
  output="$4"
  args=(
    --pid "${repo_shell_pid}"
    --mode "${mode}"
    --state "${state}"
    --crop usable
    --workspace auto
    --delay 1.2
    --output "${output}"
  )
  if [[ -n "${query}" && "${query}" != "''" ]]; then
    if [[ "${state}" == "category" ]]; then
      args+=(--category "${query}")
    else
      args+=(--query "${query}")
    fi
  fi
  bash "${REMOTE_PANEL_ROOT}/scripts/capture-launcher-viewport.sh" "${args[@]}"
done
EOF
      return 0
      ;;
    *)
      printf 'Unknown mode: %s\n' "${capture_mode}" >&2
      exit 2
      ;;
  esac

  if (( ${#extra_capture_args[@]} > 0 )); then
    local extra=""
    local arg
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

echo "[INFO] Launching Hyprland test VM on SSH port ${ssh_port}"
: > "${launcher_log}"
launcher_args=(--ssh-port "${ssh_port}")
if (( reset_disk == 1 )); then
  launcher_args+=(--reset-disk)
fi
coproc VM_LAUNCHER {
  exec env QEMU_OPTS="${qa_qemu_opts}" bash "${launcher}" "${launcher_args[@]}" >"${launcher_log}" 2>&1
}
launcher_pid="${VM_LAUNCHER_PID}"

wait_for_ssh
wait_for_hyprland

run_id="$(date +%Y%m%d-%H%M%S)-$$"
remote_repo="/tmp/nixos-config-${run_id}"
sync_repo "${remote_repo}"
run_remote_capture "${remote_repo}"
copy_artifacts_home

echo "[INFO] Host review artifacts saved to ${output_dir}"
if (( keep_vm_running == 1 )); then
  echo "[INFO] VM left running on SSH port ${ssh_port}"
fi
