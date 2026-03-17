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

source "${script_dir}/gallery-lib.sh"

usage() {
  cat <<'EOF'
Usage: capture-manual-qa-dashboard.sh [--id INSTANCE_ID] [--repo-shell] [--output-dir DIR] [--workspace current|auto|NAME] [--surface-crop surface|monitor|usable] [--settings-delay SECONDS] [--surface-delay SECONDS] [--skip-panel-bundle] [--skip-settings-laptop] [--skip-settings-wide]

Generate a review dashboard for the remaining Quickshell visual QA work.

The dashboard bundles:
  - the full panel QA matrix (launcher portrait/laptop/wide, settings portrait, surfaces)
  - dedicated settings matrices for laptop and wide layouts
  - a notes file that lists the still-manual checks (bar anchors, multibar, journal sanity)

Use --repo-shell to capture against the repo checkout instead of the managed user service.
EOF
}

write_notes() {
  cat > "${output_dir}/NOTES.md" <<EOF
# Manual QA Notes

Checklist:
- ${checklist_path}

Artifact set:
- \`panel-bundle/\`: launcher presets, portrait settings matrix, and surface matrix
- \`settings-laptop/\`: laptop-width settings review artifacts
- \`settings-wide/\`: wide-width settings review artifacts

Still manual:
- bar anchor verification on top, bottom, left, and right layouts
- multibar configuration behavior and cross-bar isolation
- runtime journal sanity while interacting with notifications, control center, AI chat, notepad, and color picker

Recommended journal command:
\`\`\`bash
journalctl --user -f | rg 'quickshell|WARN|ERROR'
\`\`\`
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id)
      instance_id="${2:-}"
      shift 2
      ;;
    --repo-shell)
      repo_shell_mode=1
      shift
      ;;
    --output-dir)
      output_dir="${2:-}"
      shift 2
      ;;
    --workspace)
      workspace_target="${2:-}"
      shift 2
      ;;
    --surface-crop)
      surface_crop="${2:-}"
      shift 2
      ;;
    --settings-delay)
      settings_delay="${2:-}"
      shift 2
      ;;
    --surface-delay)
      surface_delay="${2:-}"
      shift 2
      ;;
    --skip-panel-bundle)
      run_panel_bundle=0
      shift
      ;;
    --skip-settings-laptop)
      run_settings_laptop=0
      shift
      ;;
    --skip-settings-wide)
      run_settings_wide=0
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

if (( run_panel_bundle == 0 && run_settings_laptop == 0 && run_settings_wide == 0 )); then
  printf 'Nothing to capture. Remove at least one --skip-* flag.\n' >&2
  exit 2
fi

mkdir -p "${output_dir}"

common_args=()
if [[ -n "${instance_id}" ]]; then
  common_args+=(--id "${instance_id}")
fi
if (( repo_shell_mode == 1 )); then
  common_args+=(--repo-shell)
fi
common_args+=(--workspace "${workspace_target}")

if (( run_panel_bundle == 1 )); then
  printf '[INFO] Capturing panel bundle...\n'
  bash "${script_dir}/capture-panel-matrix.sh" \
    "${common_args[@]}" \
    --settings-preset portrait \
    --surface-crop "${surface_crop}" \
    --settings-delay "${settings_delay}" \
    --surface-delay "${surface_delay}" \
    --output-dir "${output_dir}/panel-bundle"
fi

if (( run_settings_laptop == 1 )); then
  printf '[INFO] Capturing settings matrix (laptop)...\n'
  bash "${script_dir}/capture-settings-matrix.sh" \
    "${common_args[@]}" \
    --preset laptop \
    --delay "${settings_delay}" \
    --output-dir "${output_dir}/settings-laptop"
fi

if (( run_settings_wide == 1 )); then
  printf '[INFO] Capturing settings matrix (wide)...\n'
  bash "${script_dir}/capture-settings-matrix.sh" \
    "${common_args[@]}" \
    --preset wide \
    --delay "${settings_delay}" \
    --output-dir "${output_dir}/settings-wide"
fi

write_notes

dashboard_links=()
if (( run_panel_bundle == 1 )); then
  dashboard_links+=("Panel Bundle|panel-bundle/index.html")
fi
if (( run_settings_laptop == 1 )); then
  dashboard_links+=("Settings Laptop|settings-laptop/index.html")
fi
if (( run_settings_wide == 1 )); then
  dashboard_links+=("Settings Wide|settings-wide/index.html")
fi

# Read checklist
checklist_content=""
if [[ -f "${checklist_path}" ]]; then
  checklist_content="$(cat "${checklist_path}")"
fi

# Run health check
printf '[INFO] Running system health check...\n'
health_json="$(bash "${script_dir}/health-check.sh" 2>/dev/null || true)"
if [[ -z "${health_json}" ]]; then
  health_json='{"status": "unknown", "active_signatures": []}'
fi

write_master_index "${output_dir}" "Quickshell Manual QA Dashboard" "${checklist_content}" "${health_json}" "${dashboard_links[@]}"

printf '[INFO] Saved manual QA dashboard to %s/index.html\n' "${output_dir}"
printf '[INFO] Saved notes to %s/NOTES.md\n' "${output_dir}"
