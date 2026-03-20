#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." >/dev/null 2>&1 && pwd -P)"
launcher="${repo_root}/scripts/vm/launch-hyprland-test-vm.sh"
ssh_port="${HYPRLAND_VM_QA_SSH_PORT:-2242}"
vm_password="${HYPRLAND_VM_PASSWORD:-hyprland}"
qa_qemu_opts="${HYPRLAND_VM_QA_QEMU_OPTS:--vga none -device virtio-vga -display vnc=127.0.0.1:42}"
boot_timeout="${HYPRLAND_VM_QA_BOOT_TIMEOUT:-300}"
poll_delay="${HYPRLAND_VM_QA_POLL_DELAY:-2}"
poll_attempts="${HYPRLAND_VM_QA_POLL_ATTEMPTS:-}"
output_dir="${HYPRLAND_VM_QA_OUTPUT_DIR:-/tmp/panel-qa-matrix-host}"
capture_mode="panel"
reset_disk=0
keep_vm_running=0
vm_output_dir=""
launcher_log="${HYPRLAND_VM_QA_LOG:-/tmp/hyprland-test-vm-qa.log}"
extra_capture_args=()
host_pubkey_file=""

if [[ -z "${poll_attempts}" ]]; then
  poll_attempts=$(( (boot_timeout + poll_delay - 1) / poll_delay ))
fi

usage() {
  cat <<'EOF'
Usage: run-hyprland-panel-qa.sh [--output-dir DIR] [--mode panel|settings|surfaces|launcher|settings-qa|gate]
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
  settings-qa Run check-settings-qa.sh --repo-shell and copy its artifacts/logs
  gate       Run runtime gate + settings QA and copy logs/artifacts
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

wait_for_hyprland() {
  local i
  for ((i = 1; i <= 60; i++)); do
    if "${ssh_base[@]}" '
      pgrep -af "Hyprland" >/dev/null 2>&1 &&
      systemctl --user show-environment 2>/dev/null | grep -q "^HYPRLAND_INSTANCE_SIGNATURE=" &&
      systemctl --user show-environment 2>/dev/null | grep -q "^WAYLAND_DISPLAY="
    ' >/dev/null 2>&1; then
      return 0
    fi

    "${ssh_base[@]}" '
      # Recover from stale user-session state where graphical-session.target is
      # active before Hyprland has exported its Wayland environment.
      systemctl --user reset-failed quickshell.service quickshell-health.service hyprpolkitagent.service >/dev/null 2>&1 || true
      systemctl --user stop quickshell.service quickshell-health.service >/dev/null 2>&1 || true
      pkill -x quickshell >/dev/null 2>&1 || true
      if uwsm check is-active >/dev/null 2>&1; then
        uwsm stop >/tmp/uwsm-hyprland-stop.log 2>&1 || true
        sleep 1
      fi
      if ! pgrep -af "Hyprland" >/dev/null 2>&1; then
        nohup sh -lc "exec uwsm start hyprland-uwsm.desktop >/tmp/uwsm-hyprland.log 2>&1" >/dev/null 2>&1 &
      fi
    ' >/dev/null 2>&1 || true
    sleep 2
  done

  echo "[ERROR] Expected Hyprland to be running in the VM" >&2
  "${ssh_base[@]}" '
    echo "--- processes ---"
    pgrep -a "Hyprland|quickshell|kitty|uwsm|sddm|lightdm" || true
    echo "--- quickshell status ---"
    systemctl --user status --no-pager quickshell.service 2>/dev/null || true
    echo "--- uwsm log ---"
    sed -n "1,160p" /tmp/uwsm-hyprland.log 2>/dev/null || true
    echo "--- uwsm stop log ---"
    sed -n "1,160p" /tmp/uwsm-hyprland-stop.log 2>/dev/null || true
    echo "--- env ---"
    systemctl --user show-environment 2>/dev/null | grep -E "HYPRLAND|WAYLAND|XDG_CURRENT_DESKTOP|DESKTOP_SESSION" || true
    echo "--- session ---"
    loginctl show-session "$XDG_SESSION_ID" -p Name -p Desktop -p Type 2>/dev/null || true
    echo "--- user journal ---"
    journalctl --user --no-pager -n 160 2>/dev/null || true
  ' >&2
  return 1
}

sync_repo() {
  local remote_repo="$1"
  local panel_rel="home/features/desktop/window-managers/shared/panel"
  local remote_panel_parent

  remote_panel_parent="${remote_repo}/home/features/desktop/window-managers/shared"
  echo "[INFO] Syncing repo checkout into VM: ${remote_repo}"
  "${ssh_base[@]}" "rm -rf '${remote_repo}' && mkdir -p '${remote_panel_parent}'"
  tar -C "${repo_root}" -cf - "${panel_rel}" | "${ssh_base[@]}" "tar -xf - -C '${remote_repo}'"
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
    settings-qa)
      "${ssh_base[@]}" "REMOTE_PANEL_ROOT='${remote_panel_root}' VM_OUTPUT_DIR='${vm_output_dir}' bash -s" <<'EOF'
set -euo pipefail

mkdir -p "${VM_OUTPUT_DIR}"
log_path="${VM_OUTPUT_DIR}/settings-qa.log"
artifact_dir="${VM_OUTPUT_DIR}/bar-widgets-first-open"

set -o pipefail
bash "${REMOTE_PANEL_ROOT}/scripts/check-settings-qa.sh" --repo-shell --output-dir "${artifact_dir}" 2>&1 | tee "${log_path}"
EOF
      return $?
      ;;
    gate)
      "${ssh_base[@]}" "REMOTE_PANEL_ROOT='${remote_panel_root}' VM_OUTPUT_DIR='${vm_output_dir}' bash -s" <<'EOF'
set -uo pipefail

mkdir -p "${VM_OUTPUT_DIR}"
runtime_log="${VM_OUTPUT_DIR}/runtime.log"
settings_log="${VM_OUTPUT_DIR}/settings-qa.log"
artifact_dir="${VM_OUTPUT_DIR}/bar-widgets-first-open"
runtime_status=0
settings_status=0

set -o pipefail
if bash "${REMOTE_PANEL_ROOT}/scripts/check-panel-runtime.sh" --repo-shell --skip-multibar --skip-launcher 2>&1 | tee "${runtime_log}"; then
  runtime_status=0
else
  runtime_status=$?
fi

if (( runtime_status == 0 )); then
  if bash "${REMOTE_PANEL_ROOT}/scripts/check-settings-qa.sh" --repo-shell --skip-switch --output-dir "${artifact_dir}" 2>&1 | tee "${settings_log}"; then
    settings_status=0
  else
    settings_status=$?
  fi
else
  printf '[SKIP] settings qa skipped because runtime gate failed\n' | tee "${settings_log}"
  settings_status=99
fi

cat > "${VM_OUTPUT_DIR}/gate-status.env" <<STATUS
runtime_exit=${runtime_status}
settings_exit=${settings_status}
STATUS

if (( runtime_status != 0 )); then
  exit "${runtime_status}"
fi
if (( settings_status != 0 && settings_status != 99 )); then
  exit "${settings_status}"
fi
exit 0
EOF
      return $?
      ;;
    launcher)
      "${ssh_base[@]}" "REMOTE_PANEL_ROOT='${remote_panel_root}' VM_OUTPUT_DIR='${vm_output_dir}' bash -s" <<'EOF'
set -euo pipefail

repo_shell_pid=""
service_was_active=0
repo_shell_env=()

populate_repo_shell_env() {
  local line=""
  local key=""
  local value=""

  repo_shell_env=()
  for key in HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY NIRI_SOCKET XDG_CURRENT_DESKTOP DESKTOP_SESSION; do
    value="${!key:-}"
    if [[ -n "${value}" ]]; then
      repo_shell_env+=("${key}=${value}")
    fi
  done

  if (( ${#repo_shell_env[@]} > 0 )); then
    return 0
  fi

  while IFS= read -r line; do
    [[ "${line}" == *=* ]] || continue
    key="${line%%=*}"
    value="${line#*=}"
    case "${key}" in
      HYPRLAND_INSTANCE_SIGNATURE|WAYLAND_DISPLAY|NIRI_SOCKET|XDG_CURRENT_DESKTOP|DESKTOP_SESSION)
        [[ -n "${value}" ]] && repo_shell_env+=("${key}=${value}")
        ;;
    esac
  done < <(systemctl --user show-environment 2>/dev/null || true)
}

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
populate_repo_shell_env
  env "${repo_shell_env[@]}" quickshell -p "${REMOTE_PANEL_ROOT}/src/shell.qml" >/tmp/quickshell-repo-launcher-qa.log 2>&1 &
repo_shell_pid="$!"

ready=0
for _ in $(seq 1 40); do
  if quickshell ipc --pid "${repo_shell_pid}" show >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 0.5
done

if (( ready == 0 )); then
  sed -n '1,160p' /tmp/quickshell-repo-launcher-qa.log >&2 || true
  exit 1
fi

for capture in \
  "drun|home||${VM_OUTPUT_DIR}/drun-home.png" \
  "drun|query|firefox|${VM_OUTPUT_DIR}/drun-query.png" \
  "drun|category|Utility|${VM_OUTPUT_DIR}/drun-category.png" \
  "files|empty|__launcher_empty_probe__|${VM_OUTPUT_DIR}/files-empty.png" \
  "system|home||${VM_OUTPUT_DIR}/system-home.png"
do
  IFS='|' read -r mode state query output <<<"${capture}"
  [[ -n "${mode}" && -n "${state}" && -n "${output}" ]] || {
    echo "[ERROR] Invalid launcher capture definition: ${capture}" >&2
    exit 1
  }
  args=(
    --pid "${repo_shell_pid}"
    --mode "${mode}"
    --state "${state}"
    --crop usable
    --workspace auto
    --delay 1.2
    --output "${output}"
  )
  if [[ -n "${query}" ]]; then
    if [[ "${state}" == "category" ]]; then
      args+=(--category "${query}")
    else
      args+=(--query "${query}")
    fi
  fi
  bash "${REMOTE_PANEL_ROOT}/scripts/capture-launcher-viewport.sh" "${args[@]}"
done
EOF
      return $?
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

write_summary() {
  local remote_exit="$1"
  local overall_status="pass"
  local runtime_status="n/a"
  local settings_status="n/a"
  local runtime_exit_value=""
  local settings_exit_value=""

  if [[ -f "${output_dir}/gate-status.env" ]]; then
    # shellcheck disable=SC1090
    source "${output_dir}/gate-status.env"
    runtime_exit_value="${runtime_exit:-}"
    settings_exit_value="${settings_exit:-}"
    case "${runtime_exit_value}" in
      0) runtime_status="pass" ;;
      *) runtime_status="fail" ;;
    esac
    case "${settings_exit_value}" in
      0) settings_status="pass" ;;
      99) settings_status="skip" ;;
      *) settings_status="fail" ;;
    esac
  elif [[ "${capture_mode}" == "settings-qa" ]]; then
    settings_status=$([[ "${remote_exit}" -eq 0 ]] && printf 'pass' || printf 'fail')
  fi

  if [[ "${remote_exit}" -ne 0 ]]; then
    overall_status="fail"
  fi

  cat > "${output_dir}/summary.json" <<EOF
{
  "vm": "hyprland",
  "mode": "${capture_mode}",
  "status": "${overall_status}",
  "remoteExit": ${remote_exit},
  "runtimeStatus": "${runtime_status}",
  "settingsStatus": "${settings_status}",
  "sshPort": "${ssh_port}",
  "artifactDir": "${output_dir}",
  "launcherLog": "${output_dir}/launcher.log"
}
EOF

  cat > "${output_dir}/summary.md" <<EOF
# Hyprland VM QA Summary

- mode: \`${capture_mode}\`
- status: \`${overall_status}\`
- remote exit: \`${remote_exit}\`
- runtime: \`${runtime_status}\`
- settings: \`${settings_status}\`
- artifacts: \`${output_dir}\`
- launcher log: \`${output_dir}/launcher.log\`
EOF
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
install_host_pubkey
wait_for_hyprland

run_id="$(date +%Y%m%d-%H%M%S)-$$"
remote_repo="/tmp/nixos-config-${run_id}"
sync_repo "${remote_repo}"
remote_exit=0
set +e
run_remote_capture "${remote_repo}"
remote_exit=$?
set -e
copy_artifacts_home || true
cp "${launcher_log}" "${output_dir}/launcher.log"
write_summary "${remote_exit}"

echo "[INFO] Host review artifacts saved to ${output_dir}"
if (( keep_vm_running == 1 )); then
  echo "[INFO] VM left running on SSH port ${ssh_port}"
fi

if (( remote_exit != 0 )); then
  exit "${remote_exit}"
fi
