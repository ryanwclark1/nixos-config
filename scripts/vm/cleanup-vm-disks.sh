#!/usr/bin/env bash
set -euo pipefail

# Cleanup script for VM QCOW2 disk images
# Removes old QCOW2 files based on age and/or count limits

repo_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." >/dev/null 2>&1 && pwd -P)"
state_root="${XDG_STATE_HOME:-$HOME/.local/state}/nixos-config"

# Defaults
max_age_days="${VM_DISK_CLEANUP_MAX_AGE_DAYS:-7}"
max_keep_count="${VM_DISK_CLEANUP_MAX_KEEP:-5}"
dry_run="${VM_DISK_CLEANUP_DRY_RUN:-0}"
verbose="${VM_DISK_CLEANUP_VERBOSE:-0}"

usage() {
  cat <<'EOF'
Usage: cleanup-vm-disks.sh [--vm niri|hyprland|both] [--max-age-days DAYS]
                           [--max-keep COUNT] [--dry-run] [--verbose]

Clean up old QCOW2 VM disk images from test runs.

Options:
  --vm TYPE              Clean up specific VM type (niri, hyprland, or both)
  --max-age-days DAYS    Remove files older than DAYS (default: 7)
  --max-keep COUNT       Keep only the COUNT most recent files per VM type (default: 5)
  --dry-run              Show what would be deleted without actually deleting
  --verbose              Show detailed information about each file

The cleanup applies both filters: files older than max-age-days OR beyond max-keep
count will be removed. Files are sorted by modification time (newest first).
EOF
}

vm_selector="both"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --vm)
      vm_selector="${2:-}"
      shift 2
      ;;
    --max-age-days)
      max_age_days="${2:-}"
      shift 2
      ;;
    --max-keep)
      max_keep_count="${2:-}"
      shift 2
      ;;
    --dry-run)
      dry_run=1
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

if [[ ! "${max_age_days}" =~ ^[0-9]+$ ]] || [[ "${max_age_days}" -lt 0 ]]; then
  printf 'Error: --max-age-days must be a non-negative integer\n' >&2
  exit 2
fi

if [[ ! "${max_keep_count}" =~ ^[0-9]+$ ]] || [[ "${max_keep_count}" -lt 0 ]]; then
  printf 'Error: --max-keep must be a non-negative integer\n' >&2
  exit 2
fi

case "${vm_selector}" in
  niri) selected_vms=(niri) ;;
  hyprland) selected_vms=(hyprland) ;;
  both) selected_vms=(niri hyprland) ;;
  *)
    printf 'Error: --vm must be one of: niri, hyprland, both\n' >&2
    exit 2
    ;;
esac

cleanup_vm_disks() {
  local vm_type="$1"
  local state_dir=""
  local config_name=""
  local total_size=0
  local deleted_count=0
  local deleted_size=0

  case "${vm_type}" in
    niri)
      state_dir="${state_root}/niri-test-vm"
      config_name="niriTestVm"
      ;;
    hyprland)
      state_dir="${state_root}/hyprland-test-vm"
      config_name="hyprlandTestVm"
      ;;
    *)
      printf 'Error: Unknown VM type: %s\n' "${vm_type}" >&2
      return 1
      ;;
  esac

  if [[ ! -d "${state_dir}" ]]; then
    if (( verbose == 1 )); then
      printf '[INFO] No state directory found for %s: %s\n' "${vm_type}" "${state_dir}"
    fi
    return 0
  fi

  # Find all QCOW2 files matching the pattern
  local -a qcow_files=()
  while IFS= read -r -d '' file; do
    qcow_files+=("${file}")
  done < <(find "${state_dir}" -maxdepth 1 -type f -name "${config_name}-*.qcow2" -print0 2>/dev/null | sort -z)

  if (( ${#qcow_files[@]} == 0 )); then
    if (( verbose == 1 )); then
      printf '[INFO] No QCOW2 files found for %s in %s\n' "${vm_type}" "${state_dir}"
    fi
    return 0
  fi

  # Sort by modification time (newest first)
  local -a sorted_files=()
  while IFS= read -r line; do
    [[ -n "${line}" ]] && sorted_files+=("${line}")
  done < <(printf '%s\n' "${qcow_files[@]}" | xargs -I{} sh -c 'stat -c "%Y %n" "{}"' | sort -rn | cut -d' ' -f2-)

  printf '[INFO] Found %d QCOW2 file(s) for %s VM\n' "${#sorted_files[@]}" "${vm_type}"

  # Calculate total size
  for file in "${sorted_files[@]}"; do
    if [[ -f "${file}" ]]; then
      local size
      size="$(stat -c%s "${file}" 2>/dev/null || echo 0)"
      total_size=$((total_size + size))
    fi
  done

  local current_time
  current_time="$(date +%s)"
  local cutoff_time=$((current_time - (max_age_days * 86400)))
  local keep_count=0

  for file in "${sorted_files[@]}"; do
    if [[ ! -f "${file}" ]]; then
      continue
    fi

    local mtime
    mtime="$(stat -c%Y "${file}" 2>/dev/null || echo 0)"
    local file_size
    file_size="$(stat -c%s "${file}" 2>/dev/null || echo 0)"
    local age_days=$(( (current_time - mtime) / 86400 ))
    local should_delete=0
    local reason=""

    # Check age
    if [[ "${mtime}" -lt "${cutoff_time}" ]]; then
      should_delete=1
      reason="age (${age_days} days old, >${max_age_days} days)"
    fi

    # Check count (only if not already marked for deletion by age)
    if [[ "${should_delete}" -eq 0 ]]; then
      if [[ "${keep_count}" -ge "${max_keep_count}" ]]; then
        should_delete=1
        reason="count (keeping only ${max_keep_count} most recent)"
      else
        keep_count=$((keep_count + 1))
      fi
    fi

    if [[ "${should_delete}" -eq 1 ]]; then
      local size_mb=$((file_size / 1024 / 1024))
      if (( verbose == 1 )); then
        printf '  [DELETE] %s (%d MB, %d days old) - %s\n' \
          "$(basename "${file}")" "${size_mb}" "${age_days}" "${reason}"
      else
        printf '  [DELETE] %s (%d MB) - %s\n' \
          "$(basename "${file}")" "${size_mb}" "${reason}"
      fi

      if (( dry_run == 0 )); then
        rm -f "${file}"
        deleted_count=$((deleted_count + 1))
        deleted_size=$((deleted_size + file_size))
      fi
    else
      if (( verbose == 1 )); then
        local size_mb=$((file_size / 1024 / 1024))
        printf '  [KEEP]   %s (%d MB, %d days old)\n' \
          "$(basename "${file}")" "${size_mb}" "${age_days}"
      fi
    fi
  done

  if (( deleted_count > 0 )); then
    local deleted_gb=$((deleted_size / 1024 / 1024 / 1024))
    local deleted_mb=$((deleted_size / 1024 / 1024))
    if (( deleted_gb > 0 )); then
      printf '[INFO] %s: Deleted %d file(s), freed ~%d GB\n' \
        "${vm_type}" "${deleted_count}" "${deleted_gb}"
    else
      printf '[INFO] %s: Deleted %d file(s), freed ~%d MB\n' \
        "${vm_type}" "${deleted_count}" "${deleted_mb}"
    fi
  else
    printf '[INFO] %s: No files to delete\n' "${vm_type}"
  fi

  return 0
}

if (( dry_run == 1 )); then
  printf '[DRY RUN] No files will actually be deleted\n'
  printf '[DRY RUN] Max age: %d days, Max keep: %d files per VM type\n\n' \
    "${max_age_days}" "${max_keep_count}"
fi

for vm in "${selected_vms[@]}"; do
  cleanup_vm_disks "${vm}"
done

printf '[INFO] Cleanup complete\n'
