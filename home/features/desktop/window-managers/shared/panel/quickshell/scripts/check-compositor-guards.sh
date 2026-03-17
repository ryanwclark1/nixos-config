#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
config_dir="${script_dir}/../config"

# Files intentionally compositor-scoped today.
allow_hyprctl=(
  "${config_dir}/bar/widgets/Workspaces.qml"
  "${config_dir}/launcher/Overview.qml"
  "${config_dir}/services/CompositorAdapter.qml"
  "${config_dir}/services/DependencyService.qml"
  "${config_dir}/services/NightLightService.qml"
  "${config_dir}/services/PowerService.qml"
)

allow_hyprland_import=(
  "${config_dir}/launcher/Overview.qml"
  "${config_dir}/services/CompositorAdapter.qml"
)

allow_direct_compositor_checks=(
  "${config_dir}/bar/widgets/Taskbar.qml"
  "${config_dir}/bar/widgets/TaskButton.qml"
  "${config_dir}/bar/widgets/WindowTitle.qml"
  "${config_dir}/bar/widgets/Workspaces.qml"
  "${config_dir}/launcher/AltTabSwitcher.qml"
  "${config_dir}/menu/settings/tabs/HotkeysTab.qml"
  "${config_dir}/services/CompositorAdapter.qml"
  "${config_dir}/services/NightLightService.qml"
  "${config_dir}/services/NiriBinds.qml"
  "${config_dir}/services/NiriService.qml"
  "${config_dir}/services/PowerService.qml"
  "${config_dir}/services/WorkspaceIdentityService.qml"
  "${config_dir}/shell.qml"
)

contains_path() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

violations=()

while IFS= read -r hit; do
  [[ -z "${hit}" ]] && continue
  file="${hit%%:*}"
  if ! contains_path "$file" "${allow_hyprctl[@]}"; then
    violations+=("hyprctl outside allowlist: ${hit}")
  fi
done < <(rg -n '\bhyprctl\b' "${config_dir}" --glob '*.qml' || true)

for file in "${allow_hyprctl[@]}"; do
  if ! rg -q '\bhyprctl\b' "$file"; then
    violations+=("stale hyprctl allowlist entry (no hyprctl found): ${file}")
  fi
done

while IFS= read -r hit; do
  [[ -z "${hit}" ]] && continue
  file="${hit%%:*}"
  if ! contains_path "$file" "${allow_hyprland_import[@]}"; then
    violations+=("Quickshell.Hyprland import outside allowlist: ${hit}")
  fi
done < <(rg -n '^\s*import\s+Quickshell\.Hyprland\b' "${config_dir}" --glob '*.qml' || true)

for file in "${allow_hyprland_import[@]}"; do
  if ! rg -q '^\s*import\s+Quickshell\.Hyprland\b' "$file"; then
    violations+=("stale Quickshell.Hyprland allowlist entry (import missing): ${file}")
  fi
done

while IFS= read -r hit; do
  [[ -z "${hit}" ]] && continue
  file="${hit%%:*}"
  if ! contains_path "$file" "${allow_direct_compositor_checks[@]}"; then
    violations+=("direct compositor check outside allowlist: ${hit}")
  fi
done < <(rg -n 'CompositorAdapter\.(isHyprland|isNiri)\b' "${config_dir}" --glob '*.qml' || true)

if (( ${#violations[@]} > 0 )); then
  printf '%s\n' "Compositor guard check failed:" >&2
  printf '  - %s\n' "${violations[@]}" >&2
  exit 1
fi

printf '%s\n' "Compositor guard check passed."
