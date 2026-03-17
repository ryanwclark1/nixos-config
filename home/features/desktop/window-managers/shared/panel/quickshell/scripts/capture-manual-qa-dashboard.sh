#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
repo_root="$(CDPATH= cd -- "${script_dir}/.." >/dev/null && pwd)"
checklist_path="${repo_root}/MANUAL_QA_CHECKLIST.md"

instance_id=""
repo_shell_mode=0
output_dir="/tmp/quickshell-manual-qa-$(date +%Y%m%d-%H%M%S)"
workspace_target="auto"
surface_crop="surface"
settings_delay="2.5"
surface_delay="1.6"
run_panel_bundle=1
run_settings_wide=1
run_settings_laptop=1
run_responsive=0

source "${script_dir}/gallery-lib.sh"

usage() {
  cat <<'EOF'
Usage: capture-manual-qa-dashboard.sh [OPTIONS]

Generate a review dashboard for Quickshell visual QA.

Options:
  --id INSTANCE_ID       Target a specific Quickshell instance.
  --repo-shell           Capture against the repo checkout.
  --output-dir DIR       Output directory for artifacts.
  --workspace TARGET     Workspace to use for capture.
  --surface-crop MODE    Crop mode for surfaces (surface|monitor|usable).
  --responsive           Capture all components at Portrait, Laptop, and Wide resolutions.
  --skip-panel-bundle    Skip the primary panel capture set.
  --skip-settings-laptop Skip dedicated laptop-width settings matrix.
  --skip-settings-wide   Skip dedicated wide-width settings matrix.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id) instance_id="${2:-}"; shift 2 ;;
    --repo-shell) repo_shell_mode=1; shift ;;
    --output-dir) output_dir="${2:-}"; shift 2 ;;
    --workspace) workspace_target="${2:-}"; shift 2 ;;
    --surface-crop) surface_crop="${2:-}"; shift 2 ;;
    --responsive) run_responsive=1; shift ;;
    --skip-panel-bundle) run_panel_bundle=0; shift ;;
    --skip-settings-laptop) run_settings_laptop=0; shift ;;
    --skip-settings-wide) run_settings_wide=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

mkdir -p "${output_dir}"

common_args=()
[[ -n "${instance_id}" ]] && common_args+=(--id "${instance_id}")
(( repo_shell_mode == 1 )) && common_args+=(--repo-shell)
common_args+=(--workspace "${workspace_target}")

dashboard_links=()

if (( run_panel_bundle == 1 )); then
  printf '[INFO] Capturing panel bundle...\n'
  bash "${script_dir}/capture-panel-matrix.sh" \
    "${common_args[@]}" \
    --settings-preset portrait \
    --surface-crop "${surface_crop}" \
    --settings-delay "${settings_delay}" \
    --surface-delay "${surface_delay}" \
    --output-dir "${output_dir}/panel-bundle"
  dashboard_links+=("Panel Bundle|panel-bundle/index.html")
fi

if (( run_responsive == 1 )); then
  for preset in portrait laptop wide; do
    printf '[INFO] Capturing responsive matrix (%s)...\n' "${preset}"
    
    # Launcher
    bash "${script_dir}/capture-launcher-matrix.sh" \
      "${common_args[@]}" \
      --preset "${preset}" \
      --output-dir "${output_dir}/responsive/launcher-${preset}"
    dashboard_links+=("Launcher (${preset})|responsive/launcher-${preset}/index.html")

    # Settings
    bash "${script_dir}/capture-settings-matrix.sh" \
      "${common_args[@]}" \
      --preset "${preset}" \
      --delay "${settings_delay}" \
      --output-dir "${output_dir}/responsive/settings-${preset}"
    dashboard_links+=("Settings (${preset})|responsive/settings-${preset}/index.html")
  done
else
  if (( run_settings_laptop == 1 )); then
    printf '[INFO] Capturing settings matrix (laptop)...\n'
    bash "${script_dir}/capture-settings-matrix.sh" \
      "${common_args[@]}" \
      --preset laptop \
      --delay "${settings_delay}" \
      --output-dir "${output_dir}/settings-laptop"
    dashboard_links+=("Settings Laptop|settings-laptop/index.html")
  fi

  if (( run_settings_wide == 1 )); then
    printf '[INFO] Capturing settings matrix (wide)...\n'
    bash "${script_dir}/capture-settings-matrix.sh" \
      "${common_args[@]}" \
      --preset wide \
      --delay "${settings_delay}" \
      --output-dir "${output_dir}/settings-wide"
    dashboard_links+=("Settings Wide|settings-wide/index.html")
  fi
fi

# Read checklist
checklist_content=""
[[ -f "${checklist_path}" ]] && checklist_content="$(cat "${checklist_path}")"

# Run health check
printf '[INFO] Running system health check...\n'
health_json="$(bash "${script_dir}/health-check.sh" 2>/dev/null || true)"
[[ -z "${health_json}" ]] && health_json='{"status": "unknown", "active_signatures": []}'

write_master_index "${output_dir}" "Quickshell Manual QA Dashboard" "${checklist_content}" "${health_json}" "${dashboard_links[@]}"

printf '[INFO] Saved manual QA dashboard to %s/index.html\n' "${output_dir}"
