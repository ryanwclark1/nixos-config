#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_dir="${script_dir}/../config"

# Files intentionally compositor-scoped today.
allow_hyprctl=(
  "${config_dir}/bar/widgets/Workspaces.qml"
  "${config_dir}/launcher/Launcher.qml"
  "${config_dir}/launcher/Overview.qml"
  "${config_dir}/menu/ControlCenter.qml"
  "${config_dir}/menu/DisplayConfig.qml"
  "${config_dir}/menu/HyprActions.qml"
  "${config_dir}/menu/SettingsHub.qml"
  "${config_dir}/menu/settings/tabs/HotkeysTab.qml"
  "${config_dir}/menu/settings/tabs/HyprlandTab.qml"
  "${config_dir}/menu/settings/tabs/WallpaperTab.qml"
  "${config_dir}/modules/ScratchpadWidget.qml"
  "${config_dir}/services/CompositorAdapter.qml"
  "${config_dir}/services/Config.qml"
  "${config_dir}/services/PrivacyService.qml"
  "${config_dir}/services/WallpaperService.qml"
  "${config_dir}/widgets/DockMenu.qml"
  "${config_dir}/widgets/ScratchpadIndicator.qml"
  "${config_dir}/widgets/WorkspaceOsd.qml"
)

allow_hyprland_import=(
  "${config_dir}/launcher/Overview.qml"
)

allow_direct_compositor_checks=(
  "${config_dir}/services/CompositorAdapter.qml"
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
done < <(rg -n "hyprctl" "${config_dir}" --glob '*.qml' || true)

while IFS= read -r hit; do
  [[ -z "${hit}" ]] && continue
  file="${hit%%:*}"
  if ! contains_path "$file" "${allow_hyprland_import[@]}"; then
    violations+=("Quickshell.Hyprland import outside allowlist: ${hit}")
  fi
done < <(rg -n '^\s*import\s+Quickshell\.Hyprland\b' "${config_dir}" --glob '*.qml' || true)

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
