#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." >/dev/null 2>&1 && pwd -P)"
launcher="${repo_root}/scripts/vm/launch-niri-test-vm.sh"
ssh_port="${NIRI_VM_QA_SSH_PORT:-2232}"
vm_password="${NIRI_VM_PASSWORD:-niri}"
ssh_identity_file="${NIRI_VM_SSH_IDENTITY:-}"
boot_timeout="${NIRI_VM_QA_BOOT_TIMEOUT:-300}"
poll_delay="${NIRI_VM_QA_POLL_DELAY:-2}"
poll_attempts="${NIRI_VM_QA_POLL_ATTEMPTS:-}"
niri_unit_timeout="${NIRI_VM_QA_NIRI_UNIT_TIMEOUT:-120}"
niri_session_timeout="${NIRI_VM_QA_SESSION_TIMEOUT:-120}"
output_dir="${NIRI_VM_QA_OUTPUT_DIR:-/tmp/panel-qa-matrix-niri-host}"
capture_mode="panel"
reset_disk=0
keep_vm_running=0
vm_output_dir=""
launcher_log="${NIRI_VM_QA_LOG:-}"
extra_capture_args=()
host_pubkey_file=""
use_key_auth=0
key_auth_ready=0
remote_runtime_dir=""
remote_repo=""
remote_tmp_root=""
remote_state_home=""

if [[ -z "${poll_attempts}" ]]; then
  poll_attempts=$(( (boot_timeout + poll_delay - 1) / poll_delay ))
fi

usage() {
  cat <<'EOF'
Usage: run-niri-panel-qa.sh [--output-dir DIR] [--mode panel|settings|surfaces|settings-qa|gate]
                           [--ssh-port PORT] [--reset-disk] [--keep-vm-running]
                           [--vm-output-dir DIR] [-- <extra capture args>]

Boot a dedicated Niri VM, sync the panel repo subtree into the guest, run the
selected Quickshell capture flow inside the VM, and copy the resulting artifact
directory back to the host.

Modes:
  panel      Run capture-panel-matrix.sh --repo-shell --skip-launcher
  settings   Run capture-panel-matrix.sh --repo-shell --skip-surfaces --skip-launcher
  surfaces   Run capture-panel-matrix.sh --repo-shell --skip-settings --skip-launcher
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

if [[ -z "${launcher_log}" ]]; then
  launcher_log="/tmp/niri-test-vm-qa-${ssh_port}.log"
fi

if [[ -z "${vm_output_dir}" ]]; then
  vm_output_dir="__AUTO__"
fi

mkdir -p "${output_dir}"

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

scp_common_opts=(
  -o LogLevel=ERROR
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
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
    -p "${ssh_port}"
    administrator@127.0.0.1
  )

  scp_key_base=(
    scp
    "${scp_common_opts[@]}"
    -o PreferredAuthentications=publickey
    -o PubkeyAuthentication=yes
    -o PasswordAuthentication=no
    -o IdentitiesOnly=yes
    -i "${ssh_identity_file}"
    -P "${ssh_port}"
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
  -p "${ssh_port}"
  administrator@127.0.0.1
)

scp_password_base=(
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
  "${scp_common_opts[@]}"
  -o PreferredAuthentications=password
  -o PubkeyAuthentication=no
  -P "${ssh_port}"
)

vm_ssh() {
  if (( use_key_auth == 1 && key_auth_ready == 1 )); then
    "${ssh_key_base[@]}" "$@"
    return $?
  fi

  "${ssh_password_base[@]}" "$@"
}

vm_scp() {
  if (( use_key_auth == 1 && key_auth_ready == 1 )); then
    "${scp_key_base[@]}" "$@"
    return $?
  fi

  "${scp_password_base[@]}" "$@"
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

resolve_remote_paths() {
  remote_runtime_dir="$(vm_ssh 'printf %s "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"' 2>/dev/null || true)"
  if [[ -z "${remote_runtime_dir}" ]]; then
    remote_runtime_dir="/run/user/1000"
  fi

  remote_tmp_root="${remote_runtime_dir}/panel-qa"
  remote_state_home="${remote_tmp_root}/state"
  remote_repo="${remote_tmp_root}/repo"
  if [[ "${vm_output_dir}" == "__AUTO__" ]]; then
    vm_output_dir="${remote_tmp_root}/artifacts/${capture_mode}-$(date +%Y%m%d-%H%M%S)"
  fi

  vm_ssh "mkdir -p '${remote_tmp_root}' '${remote_state_home}' '${vm_output_dir}'"
}

prepare_guest_runtime() {
  vm_ssh "
    mkdir -p '${remote_tmp_root}' '${remote_state_home}' '${vm_output_dir}' &&
    { systemctl --user stop quickshell.service >/dev/null 2>&1 || true; } &&
    { pkill -x quickshell >/dev/null 2>&1 || true; } &&
    rm -rf '${remote_repo}'
  "
}

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
    if vm_ssh "echo READY" >/dev/null 2>&1; then
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

  "${ssh_password_base[@]}" "HOST_PUBKEY=$(printf '%q' "${pubkey}") bash -s" <<'EOF'
set -euo pipefail
umask 077
mkdir -p ~/.ssh
touch ~/.ssh/authorized_keys
grep -qxF "${HOST_PUBKEY}" ~/.ssh/authorized_keys || printf '%s\n' "${HOST_PUBKEY}" >> ~/.ssh/authorized_keys
EOF

  if (( use_key_auth == 1 )) && "${ssh_key_base[@]}" "echo READY" >/dev/null 2>&1; then
    key_auth_ready=1
  fi
}

wait_for_niri() {
  local i
  if ! wait_for_niri_unit; then
    echo "[ERROR] Timed out waiting for niri.service to be registered in the VM user manager" >&2
    vm_ssh '
      echo "--- sessions ---"
      loginctl list-sessions --no-legend || true
      echo "--- user units ---"
      systemctl --user list-unit-files "niri*" || true
    ' >&2 || true
    return 1
  fi

  local deadline=$((SECONDS + niri_session_timeout))
  while (( SECONDS < deadline )); do
    if vm_ssh '
      pgrep -fa "niri --session" >/dev/null 2>&1 &&
      systemctl --user show-environment 2>/dev/null | grep -q "^NIRI_SOCKET=" &&
      systemctl --user show-environment 2>/dev/null | grep -q "^WAYLAND_DISPLAY="
    ' >/dev/null 2>&1; then
      return 0
    fi
    vm_ssh '
      systemctl --user reset-failed niri.service >/dev/null 2>&1 || true
      timeout 15s systemctl --user start niri.service >/dev/null 2>&1 || true
    ' >/dev/null 2>&1 || true
    sleep 2
  done

  echo "[ERROR] Expected Niri session to be running in the VM" >&2
  vm_ssh '
    echo "--- processes ---"
    pgrep -a "niri|quickshell|kitty|uwsm|sddm" || true
    echo "--- niri.service ---"
    systemctl --user status --no-pager niri.service 2>/dev/null || true
    echo "--- env ---"
    systemctl --user show-environment 2>/dev/null | grep -E "NIRI|WAYLAND|XDG_CURRENT_DESKTOP|DESKTOP_SESSION|XDG_SESSION_TYPE" || true
    echo "--- session ---"
    loginctl show-session "$XDG_SESSION_ID" -p Name -p Desktop -p Type 2>/dev/null || true
    echo "--- user journal ---"
    journalctl --user --no-pager -n 120 2>/dev/null || true
    echo "--- niri journal ---"
    journalctl --user --no-pager -u niri.service -n 120 2>/dev/null || true
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
  vm_ssh "rm -rf '${remote_repo}' && mkdir -p '${remote_panel_parent}'"
  tar -C "${repo_root}" -cf - "${panel_rel}" | vm_ssh "tar -xf - -C '${remote_repo}'"
}

run_remote_capture() {
  local remote_repo="$1"
  local remote_panel_root="${remote_repo}/home/features/desktop/window-managers/shared/panel/quickshell"
  local remote_cmd=""
  local extra=""
  local arg

  case "${capture_mode}" in
    panel)
      remote_cmd="env TMPDIR='${remote_tmp_root}' XDG_STATE_HOME='${remote_state_home}' bash '${remote_panel_root}/scripts/capture-panel-matrix.sh' --repo-shell --skip-launcher --output-dir '${vm_output_dir}'"
      ;;
    settings)
      remote_cmd="env TMPDIR='${remote_tmp_root}' XDG_STATE_HOME='${remote_state_home}' bash '${remote_panel_root}/scripts/capture-panel-matrix.sh' --repo-shell --skip-surfaces --skip-launcher --output-dir '${vm_output_dir}'"
      ;;
    surfaces)
      remote_cmd="env TMPDIR='${remote_tmp_root}' XDG_STATE_HOME='${remote_state_home}' bash '${remote_panel_root}/scripts/capture-panel-matrix.sh' --repo-shell --skip-settings --skip-launcher --output-dir '${vm_output_dir}'"
      ;;
    settings-qa)
      vm_ssh "TMPDIR='${remote_tmp_root}' XDG_STATE_HOME='${remote_state_home}' REMOTE_PANEL_ROOT='${remote_panel_root}' VM_OUTPUT_DIR='${vm_output_dir}' bash -s" <<'EOF'
set -euo pipefail

mkdir -p "${VM_OUTPUT_DIR}"
log_path="${VM_OUTPUT_DIR}/settings-qa.log"
artifact_dir="${VM_OUTPUT_DIR}/bar-widgets-first-open"

set -o pipefail
bash "${REMOTE_PANEL_ROOT}/scripts/check-settings-qa.sh" --repo-shell --skip-switch --output-dir "${artifact_dir}" 2>&1 | tee "${log_path}"
EOF
      return $?
      ;;
    gate)
      vm_ssh "TMPDIR='${remote_tmp_root}' XDG_STATE_HOME='${remote_state_home}' REMOTE_PANEL_ROOT='${remote_panel_root}' VM_OUTPUT_DIR='${vm_output_dir}' bash -s" <<'EOF'
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
  vm_ssh "${remote_cmd}"
}

copy_artifacts_home() {
  echo "[INFO] Copying artifacts back to host: ${output_dir}"
  rm -rf "${output_dir}"
  mkdir -p "${output_dir}"
  vm_scp -r "administrator@127.0.0.1:${vm_output_dir}/." "${output_dir}/"
}

assert_expected_artifacts() {
  local missing=0
  local required=""

  case "${capture_mode}" in
    gate)
      for required in runtime.log settings-qa.log gate-status.env; do
        if [[ ! -f "${output_dir}/${required}" ]]; then
          echo "[ERROR] Missing expected gate artifact: ${output_dir}/${required}" >&2
          missing=1
        fi
      done
      ;;
    settings-qa)
      if [[ ! -f "${output_dir}/settings-qa.log" ]]; then
        echo "[ERROR] Missing expected settings QA log: ${output_dir}/settings-qa.log" >&2
        missing=1
      fi
      ;;
  esac

  return "${missing}"
}

assert_headless_skip_markers() {
  local settings_log="${output_dir}/settings-qa.log"

  case "${capture_mode}" in
    settings-qa|gate) ;;
    *)
      return 0
      ;;
  esac

  if [[ ! -f "${settings_log}" ]]; then
    echo "[ERROR] Expected settings QA log at ${settings_log}" >&2
    return 1
  fi

  if rg -Fq "[SKIP] settings qa skipped because runtime gate failed" "${settings_log}"; then
    return 0
  fi

  rg -Fq "[SKIP] Bar Widgets first-open visual capture skipped: Niri session exposes no wl_output in this headless VM." "${settings_log}" || {
    echo "[ERROR] Missing headless Niri Bar Widgets skip marker in ${settings_log}" >&2
    return 1
  }

  rg -Fq "[INFO] Skipping runtime warning regression artifact capture: Niri session exposes no wl_output in this headless VM." "${settings_log}" || {
    echo "[ERROR] Missing headless Niri runtime-warning skip marker in ${settings_log}" >&2
    return 1
  }

  echo "[INFO] Verified headless Niri skip markers in ${settings_log}"
}

write_summary() {
  local remote_exit="$1"
  local overall_status="pass"
  local runtime_status="n/a"
  local settings_status="n/a"
  local runtime_exit_value=""
  local settings_exit_value=""
  local summary_mode=""
  local summary_overall=""
  local summary_runtime=""
  local summary_settings=""
  local summary_output_dir=""
  local summary_ssh_port=""

  if [[ -f "${output_dir}/gate-status.env" ]]; then
    runtime_exit_value="$(grep '^runtime_exit=' "${output_dir}/gate-status.env" | cut -d= -f2- || true)"
    settings_exit_value="$(grep '^settings_exit=' "${output_dir}/gate-status.env" | cut -d= -f2- || true)"
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

  if [[ "${remote_exit}" -ne 0 ]] || [[ "${runtime_status}" == "fail" ]] || [[ "${settings_status}" == "fail" ]]; then
    overall_status="fail"
  fi

  summary_mode="${capture_mode:-unknown}"
  summary_overall="${overall_status:-fail}"
  summary_runtime="${runtime_status:-n/a}"
  summary_settings="${settings_status:-n/a}"
  summary_output_dir="${output_dir:-}"
  summary_ssh_port="${ssh_port:-}"

  cat > "${output_dir}/summary.json" <<EOF
{
  "vm": "niri",
  "mode": "${summary_mode}",
  "status": "${summary_overall}",
  "remoteExit": ${remote_exit},
  "runtimeStatus": "${summary_runtime}",
  "settingsStatus": "${summary_settings}",
  "sshPort": "${summary_ssh_port}",
  "artifactDir": "${summary_output_dir}",
  "launcherLog": "${summary_output_dir}/launcher.log"
}
EOF

  printf '%s\n' \
    '# Niri VM QA Summary' \
    '' \
    "- mode: \`${summary_mode}\`" \
    "- status: \`${summary_overall}\`" \
    "- remote exit: \`${remote_exit}\`" \
    "- runtime: \`${summary_runtime}\`" \
    "- settings: \`${summary_settings}\`" \
    "- artifacts: \`${summary_output_dir}\`" \
    "- launcher log: \`${summary_output_dir}/launcher.log\`" \
    > "${output_dir}/summary.md"
}

echo "[INFO] Launching Niri test VM on SSH port ${ssh_port}"
if (( use_key_auth == 1 )); then
  echo "[INFO] Using SSH identity ${ssh_identity_file} for Niri VM access"
else
  echo "[INFO] Using password-based SSH fallback for Niri VM access"
fi
: > "${launcher_log}"
launcher_args=(--ssh-port "${ssh_port}")
if (( reset_disk == 1 )); then
  launcher_args+=(--reset-disk)
fi
bash "${launcher}" "${launcher_args[@]}" >"${launcher_log}" 2>&1 &
launcher_pid=$!

wait_for_ssh
install_host_pubkey
wait_for_niri

run_id="$(date +%Y%m%d-%H%M%S)-$$"
resolve_remote_paths
remote_repo="${remote_repo}-${run_id}"
prepare_guest_runtime
sync_repo "${remote_repo}"
remote_exit=0
set +e
run_remote_capture "${remote_repo}"
remote_exit=$?
set -e
if ! copy_artifacts_home; then
  echo "[ERROR] Failed to copy VM artifacts from ${vm_output_dir}" >&2
  if (( remote_exit == 0 )); then
    remote_exit=1
  fi
fi
cp "${launcher_log}" "${output_dir}/launcher.log"
if ! assert_expected_artifacts; then
  if (( remote_exit == 0 )); then
    remote_exit=1
  fi
fi
if ! assert_headless_skip_markers; then
  if (( remote_exit == 0 )); then
    remote_exit=1
  fi
fi
write_summary "${remote_exit}"

echo "[INFO] Host review artifacts saved to ${output_dir}"
if (( keep_vm_running == 1 )); then
  echo "[INFO] VM left running on SSH port ${ssh_port}"
fi

if (( remote_exit != 0 )); then
  exit "${remote_exit}"
fi
