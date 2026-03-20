#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." >/dev/null 2>&1 && pwd -P)"
state_root="${XDG_STATE_HOME:-$HOME/.local/state}/nixos-config/quickshell-vm-tests"
timestamp="$(date +%Y%m%d-%H%M%S)"
output_dir="${QUICKSHELL_VM_TEST_OUTPUT_DIR:-${state_root}/${timestamp}}"
vm_selector="both"
niri_ssh_port="${NIRI_VM_QA_SSH_PORT:-2232}"
hyprland_ssh_port="${HYPRLAND_VM_QA_SSH_PORT:-2242}"
reset_disk=0
keep_vm_running=0
fail_fast=0
verbose=0

usage() {
  cat <<'EOF'
Usage: run-quickshell-test-vm.sh [--vm niri|hyprland|both] [--output-dir DIR]
                                 [--niri-ssh-port PORT] [--hyprland-ssh-port PORT]
                                 [--reset-disk] [--keep-vm-running] [--fail-fast] [--verbose]

Run the focused quickshell Vitest suite inside the selected compositor VMs and
copy per-VM logs plus an aggregate summary back to the host.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vm)
      vm_selector="${2:-}"
      shift 2
      ;;
    --output-dir)
      output_dir="${2:-}"
      shift 2
      ;;
    --niri-ssh-port)
      niri_ssh_port="${2:-}"
      shift 2
      ;;
    --hyprland-ssh-port)
      hyprland_ssh_port="${2:-}"
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
    --fail-fast)
      fail_fast=1
      shift
      ;;
    --verbose)
      verbose=1
      shift
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

case "${vm_selector}" in
  niri) selected_vms=(niri) ;;
  hyprland) selected_vms=(hyprland) ;;
  both) selected_vms=(niri hyprland) ;;
  *)
    printf 'Unsupported VM selector: %s\n' "${vm_selector}" >&2
    exit 2
    ;;
esac

mkdir -p "${output_dir}"

host_log_for_vm() {
  local vm="$1"
  printf '%s/.host/%s/host-run.log' "${output_dir}" "${vm}"
}

run_one_vm() {
  local vm="$1"
  local wrapper=""
  local ssh_port=""
  local vm_dir="${output_dir}/${vm}"
  local host_log=""
  local host_meta_dir=""
  local exit_code=0
  local -a cmd=()

  case "${vm}" in
    niri)
      wrapper="${repo_root}/scripts/vm/run-niri-panel-qa.sh"
      ssh_port="${niri_ssh_port}"
      ;;
    hyprland)
      wrapper="${repo_root}/scripts/vm/run-hyprland-panel-qa.sh"
      ssh_port="${hyprland_ssh_port}"
      ;;
    *)
      printf 'Unsupported VM: %s\n' "${vm}" >&2
      return 2
      ;;
  esac

  mkdir -p "${vm_dir}"
  host_log="$(host_log_for_vm "${vm}")"
  host_meta_dir="$(dirname "${host_log}")"
  mkdir -p "${host_meta_dir}"
  cmd=(bash "${wrapper}" --mode vitest --output-dir "${vm_dir}" --ssh-port "${ssh_port}")
  if (( reset_disk == 1 )); then
    cmd+=(--reset-disk)
  fi
  if (( keep_vm_running == 1 )); then
    cmd+=(--keep-vm-running)
  fi

  printf '[INFO] Running %s VM Vitest suite\n' "${vm}"
  if (( verbose == 1 )); then
    printf '[INFO] Command:'
    printf ' %q' "${cmd[@]}"
    printf '\n'
  fi

  if "${cmd[@]}" >"${host_log}" 2>&1; then
    exit_code=0
  else
    exit_code=$?
  fi

  if [[ -f "${host_log}" ]]; then
    cat "${host_log}"
  else
    printf '[WARN] Host log missing for %s VM run: %s\n' "${vm}" "${host_log}" >&2
  fi

  printf '%s' "${exit_code}" > "${vm_dir}/exit-code.txt"
  if [[ -f "${host_log}" ]]; then
    cp "${host_log}" "${vm_dir}/aggregate-host-run.log"
  fi

  return "${exit_code}"
}

overall_status="pass"
failed_vms=()
processed_vms=()

for vm in "${selected_vms[@]}"; do
  processed_vms+=("${vm}")
  if ! run_one_vm "${vm}"; then
    overall_status="fail"
    failed_vms+=("${vm}")
    if (( fail_fast == 1 )); then
      break
    fi
  fi
done

summary_json="${output_dir}/summary.json"
summary_md="${output_dir}/summary.md"

{
  printf '{\n'
  printf '  "status": "%s",\n' "${overall_status}"
  printf '  "vmSelector": "%s",\n' "${vm_selector}"
  printf '  "outputDir": "%s",\n' "${output_dir}"
  printf '  "vms": [\n'
  for i in "${!processed_vms[@]}"; do
    vm="${processed_vms[$i]}"
    vm_dir="${output_dir}/${vm}"
    exit_code="$(cat "${vm_dir}/exit-code.txt" 2>/dev/null || printf '1')"
    sep=","
    if (( i == ${#processed_vms[@]} - 1 )); then
      sep=""
    fi
    printf '    {\n'
    printf '      "name": "%s",\n' "${vm}"
    printf '      "status": "%s",\n' "$([[ "${exit_code}" == "0" ]] && printf 'pass' || printf 'fail')"
    printf '      "exitCode": %s,\n' "${exit_code}"
    printf '      "testsStatus": "%s",\n' "$([[ "${exit_code}" == "0" ]] && printf 'pass' || printf 'fail')"
    printf '      "artifactDir": "%s",\n' "${vm_dir}"
    printf '      "hostLog": "%s"\n' "$(host_log_for_vm "${vm}")"
    printf '    }%s\n' "${sep}"
  done
  printf '  ]\n'
  printf '}\n'
} > "${summary_json}"

{
  printf '# Quickshell VM Test Summary\n\n'
  printf -- '- status: `%s`\n' "${overall_status}"
  printf -- '- selection: `%s`\n' "${vm_selector}"
  printf -- '- artifacts: `%s`\n' "${output_dir}"
  if (( ${#failed_vms[@]} > 0 )); then
    printf -- '- failed VMs: `%s`\n' "$(IFS=', '; printf '%s' "${failed_vms[*]}")"
  fi
  printf '\n'
  for vm in "${processed_vms[@]}"; do
    vm_dir="${output_dir}/${vm}"
    exit_code="$(cat "${vm_dir}/exit-code.txt" 2>/dev/null || printf '1')"
    printf '## %s\n\n' "${vm}"
    printf -- '- status: `%s`\n' "$([[ "${exit_code}" == "0" ]] && printf 'pass' || printf 'fail')"
    printf -- '- exit code: `%s`\n' "${exit_code}"
    printf -- '- tests: `%s`\n' "$([[ "${exit_code}" == "0" ]] && printf 'pass' || printf 'fail')"
    printf -- '- artifacts: `%s`\n' "${vm_dir}"
    printf -- '- host log: `%s`\n' "$(host_log_for_vm "${vm}")"
    printf -- '- wrapper summary: `%s`\n\n' "${vm_dir}/summary.json"
  done
} > "${summary_md}"

printf '[INFO] Aggregate artifacts saved to %s\n' "${output_dir}"
printf '[INFO] Summary written to %s\n' "${summary_json}"

if [[ "${overall_status}" != "pass" ]]; then
  exit 1
fi
