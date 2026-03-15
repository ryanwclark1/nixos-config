#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

mode="${1:-quick}"
reference_dir_name="reference-local-toolkit"
reference_plugin_id="reference.local.toolkit"
reference_source_dir="$(cd "${script_dir}/../examples/plugins/${reference_dir_name}" 2>/dev/null && pwd || true)"
reference_state_fixture="${reference_source_dir}/expected-state-envelope.json"
reference_settings_fixture="${reference_source_dir}/expected-settings.json"
reference_recovery_fixture="${reference_source_dir}/expected-recovery-scenarios.json"
reference_diag_active_fixture="${reference_source_dir}/expected-diagnostics-active.json"
reference_diag_degraded_fixture="${reference_source_dir}/expected-diagnostics-degraded.json"
shell_config="${script_dir}/../config/shell.qml"
docker_plugin_dir_name="docker-manager"
docker_plugin_id="docker.manager"
docker_source_dir="$(cd "${script_dir}/../examples/plugins/${docker_plugin_dir_name}" 2>/dev/null && pwd || true)"
docker_manifest="${docker_source_dir}/manifest.json"
docker_readme="${docker_source_dir}/README.md"

docker_guard_commands() {
  if [[ "${PLUGIN_LOCAL_DOCKER_SKIP_LOCAL:-0}" != "1" ]]; then
    printf '%s\n' "${script_dir}/check-plugin-docker-manager-local.sh"
  fi
  cat <<EOF
${script_dir}/check-plugin-docker-manager-runtime-smoke.sh
${script_dir}/check-plugin-docker-manager-contracts.sh
${script_dir}/check-plugin-docker-manager-diagnostics.sh
EOF
}

docker_guard_label() {
  local guard_cmd="$1"
  case "$guard_cmd" in
    *"check-plugin-docker-manager-local.sh")
      printf '%s' 'docker-manager local checks'
      ;;
    *"check-plugin-docker-manager-runtime-smoke.sh")
      printf '%s' 'docker-manager runtime smoke checks'
      ;;
    *"check-plugin-docker-manager-contracts.sh")
      printf '%s' 'docker-manager contract checks'
      ;;
    *"check-plugin-docker-manager-diagnostics.sh")
      printf '%s' 'docker-manager diagnostics checks'
      ;;
    *)
      printf '%s' 'docker-manager guard'
      ;;
  esac
}

quickshell_guard_commands() {
  cat <<EOF
${script_dir}/check-quickshell-startup.sh
${script_dir}/check-panel-runtime.sh --repo-shell
EOF
}

quickshell_guard_label() {
  local guard_cmd="$1"
  case "$guard_cmd" in
    *"check-quickshell-startup.sh")
      printf '%s' 'quickshell startup smoke'
      ;;
    *"check-panel-runtime.sh --repo-shell")
      printf '%s' 'quickshell repo-shell runtime aggregate (settings, surfaces, and multibar when supported)'
      ;;
    *"check-panel-runtime.sh")
      printf '%s' 'quickshell panel runtime aggregate'
      ;;
    *)
      printf '%s' 'quickshell runtime guard'
      ;;
  esac
}

health_label() {
  local ok="$1"
  local label="$2"
  if [[ "$ok" == "1" ]]; then
    printf 'ok: %s' "$label"
  else
    printf 'missing: %s' "$label"
  fi
}

reference_guard_commands() {
  local quiet_mode="${1:-0}"
  local silent_preflight="${2:-0}"
  local preflight_cmd="${script_dir}/plugin-local.sh reference-status --check --quiet"
  if [[ "$quiet_mode" == "1" ]]; then
    preflight_cmd="${preflight_cmd} --silent-pass"
  fi
  if [[ "$silent_preflight" == "1" ]]; then
    preflight_cmd="${preflight_cmd} --silent-status"
  fi
  cat <<EOF
${preflight_cmd}
${script_dir}/check-plugin-reference-local.sh
${script_dir}/check-plugin-reference-contracts.sh
${script_dir}/check-plugin-reference-fixtures.sh
${script_dir}/check-plugin-reference-recovery.sh
${script_dir}/check-plugin-reference-diagnostics.sh
EOF
}

reference_guard_label() {
  local guard_cmd="$1"
  case "$guard_cmd" in
    *"reference-status --check --quiet")
      printf '%s' 'reference plugin preflight'
      ;;
    *"check-plugin-reference-local.sh")
      printf '%s' 'reference plugin install/smoke/remove checks'
      ;;
    *"check-plugin-reference-contracts.sh")
      printf '%s' 'reference plugin contract checks'
      ;;
    *"check-plugin-reference-fixtures.sh")
      printf '%s' 'reference plugin fixture checks'
      ;;
    *"check-plugin-reference-recovery.sh")
      printf '%s' 'reference plugin recovery checks'
      ;;
    *"check-plugin-reference-diagnostics.sh")
      printf '%s' 'reference plugin diagnostics checks'
      ;;
    *)
      printf '%s' 'reference plugin guard'
      ;;
  esac
}

usage() {
  cat <<'EOF'
Usage:
  plugin-local.sh [quick|full|doctor|install-reference|remove-reference|smoke-reference|reference-flow|reference-export|reference-status|reference-files|reference-guards|reference-all|install-docker-manager|remove-docker-manager|smoke-docker-manager|docker-flow|docker-status|docker-files|docker-guards|docker-all|quickshell-flow|quickshell-status|quickshell-files|quickshell-guards|quickshell-all|live-gates|shared-gates|baseline-gates|all-gates] [plugins_dir|--check|--quiet]

Modes:
  quick              Run fast local plugin guardrails (default, `--quiet` suppresses wrapper headings)
  full               Run complete local plugin verification gate (`--quiet` suppresses the top-level wrapper line)
  doctor             Run plugin doctor against optional plugins_dir
  install-reference  Link the repo-tracked reference plugin into plugins_dir
  remove-reference   Remove the linked reference plugin from plugins_dir
  smoke-reference    Validate the installed reference plugin in isolation
  reference-flow     Print the manual reference-plugin validation sequence
  reference-export   Print the reference diagnostics export paths and fixtures
  reference-status   Print a combined local reference-plugin status summary (`--check` fails on unhealthy prerequisites, `--quiet` suppresses the dashboard and prints one-line status)
  reference-files    Print canonical reference toolkit file and guard paths only
  reference-guards   Print runnable reference toolkit guard commands in order
  reference-all      Run the full reference-toolkit guard sequence (`--quiet` suppresses stage headings, `--silent-preflight` suppresses successful preflight output)
  install-docker-manager Link the repo-tracked docker-manager plugin into plugins_dir
  remove-docker-manager  Remove the linked docker-manager plugin from plugins_dir
  smoke-docker-manager   Validate the installed docker-manager plugin in isolation
  docker-flow        Print the manual docker-manager validation sequence
  docker-status      Print a combined docker-manager status summary (`--check` fails on unhealthy prerequisites, `--quiet` suppresses the dashboard and prints one-line status)
  docker-files       Print canonical docker-manager file and guard paths only
  docker-guards      Print runnable docker-manager guard commands in order
  docker-all         Run the full docker-manager guard sequence (`--quiet` suppresses stage headings)
  quickshell-flow    Print the manual Quickshell runtime validation sequence
  quickshell-status  Print a combined Quickshell runtime status summary (`--check` fails on missing prerequisites or inactive service, `--quiet` suppresses the dashboard and prints one-line status)
  quickshell-files   Print canonical Quickshell shell/runtime script and guard paths only
  quickshell-guards  Print runnable Quickshell runtime guard commands in order
  quickshell-all     Run the full Quickshell runtime guard sequence (`--quiet` suppresses stage headings)
  live-gates         Run shared plugin/runtime guards plus the live Quickshell runtime workflow (`--quiet` suppresses wrapper headings)
  shared-gates       Run the shared Quickshell startup, runtime, and diagnostics plugin gates (`--quiet` suppresses wrapper headings)
  baseline-gates     Run plugin conformance and doctor-smoke gates (`--quiet` suppresses wrapper headings)
  all-gates          Run baseline, reference, and shared plugin gates (`--quiet` suppresses phase headings)
EOF
}

case "$mode" in
  quick)
    quiet=0
    if [[ "${2:-}" == "--quiet" ]]; then
      quiet=1
    fi
    if (( quiet == 0 )); then
      printf '[INFO] Local quick plugin checks...\n'
      "${script_dir}/plugin-local.sh" reference-all --quiet --silent-preflight
      "${script_dir}/plugin-local.sh" shared-gates
      printf '[INFO] Local quick plugin checks passed.\n'
    else
      "${script_dir}/plugin-local.sh" reference-all --quiet --silent-preflight
      "${script_dir}/plugin-local.sh" shared-gates --quiet
    fi
    ;;
  full)
    if [[ "${2:-}" != "--quiet" ]]; then
      printf '[INFO] Local full plugin checks...\n'
      "${script_dir}/plugin-local.sh" all-gates
    else
      "${script_dir}/plugin-local.sh" all-gates --quiet
    fi
    ;;
  doctor)
    target="${2:-${HOME}/.config/quickshell/plugins}"
    printf '[INFO] Running plugin doctor for %s...\n' "$target"
    "${script_dir}/plugin-doctor.sh" "$target"
    ;;
  install-reference)
    target="${2:-${HOME}/.config/quickshell/plugins}"
    destination="${target}/${reference_dir_name}"
    if [[ ! -d "$reference_source_dir" ]]; then
      echo "[FAIL] Missing reference plugin source: ${reference_source_dir}" >&2
      exit 1
    fi
    mkdir -p "$target"
    if [[ -e "$destination" && ! -L "$destination" ]]; then
      echo "[FAIL] Refusing to overwrite non-symlink path: ${destination}" >&2
      exit 1
    fi
    if [[ -L "$destination" ]]; then
      current_target="$(readlink "$destination" || true)"
      if [[ "$current_target" == "$reference_source_dir" ]]; then
        printf '[INFO] Reference plugin already linked at %s\n' "$destination"
        exit 0
      fi
      echo "[FAIL] Refusing to replace symlink with different target: ${destination}" >&2
      exit 1
    fi
    ln -s "$reference_source_dir" "$destination"
    printf '[INFO] Installed reference plugin at %s\n' "$destination"
    ;;
  remove-reference)
    target="${2:-${HOME}/.config/quickshell/plugins}"
    destination="${target}/${reference_dir_name}"
    if [[ ! -e "$destination" ]]; then
      printf '[INFO] Reference plugin is not installed at %s\n' "$destination"
      exit 0
    fi
    if [[ ! -L "$destination" ]]; then
      echo "[FAIL] Refusing to remove non-symlink path: ${destination}" >&2
      exit 1
    fi
    current_target="$(readlink "$destination" || true)"
    if [[ "$current_target" != "$reference_source_dir" ]]; then
      echo "[FAIL] Refusing to remove symlink with different target: ${destination}" >&2
      exit 1
    fi
    rm "$destination"
    printf '[INFO] Removed reference plugin from %s\n' "$destination"
    ;;
  smoke-reference)
    target="${2:-${HOME}/.config/quickshell/plugins}"
    destination="${target}/${reference_dir_name}"
    manifest_path="${destination}/manifest.json"
    tmp_plugins="$(mktemp -d)"
    tmp_json="$(mktemp)"
    trap 'rm -rf "$tmp_plugins" "$tmp_json"' EXIT
    if [[ ! -f "$manifest_path" ]]; then
      echo "[FAIL] Reference plugin manifest not found: ${manifest_path}" >&2
      exit 1
    fi
    if ! jq -e --arg id "$reference_plugin_id" '.id == $id' "$manifest_path" >/dev/null 2>&1; then
      echo "[FAIL] Reference plugin manifest has unexpected id: ${manifest_path}" >&2
      exit 1
    fi
    if [[ ! -L "$destination" ]]; then
      echo "[FAIL] Reference plugin path is not the expected symlink: ${destination}" >&2
      exit 1
    fi
    current_target="$(readlink "$destination" || true)"
    if [[ "$current_target" != "$reference_source_dir" ]]; then
      echo "[FAIL] Reference plugin symlink has unexpected target: ${destination}" >&2
      exit 1
    fi
    cp -RL "$destination" "${tmp_plugins}/${reference_dir_name}"
    "${script_dir}/plugin-doctor.sh" --json "$tmp_plugins" > "$tmp_json"
    jq -e --arg name "$reference_dir_name" '
      .summary.fail == 0
      and .summary.pass == 1
      and ([.entries[] | select(.status == "PASS" and .name == $name)] | length) == 1
    ' "$tmp_json" >/dev/null 2>&1
    printf '[INFO] Reference plugin smoke passed for %s\n' "$destination"
    ;;
  reference-flow)
    cat <<'EOF'
Reference Plugin Manual Flow

1. Run `scripts/plugin-local.sh install-reference` and `scripts/plugin-local.sh smoke-reference`.
2. Open Settings -> Plugins, confirm `Reference Local Toolkit` is present and enabled, then run `scripts/plugin-local.sh quick`.
3. Open launcher mode and query `!ref`, then run the `Increment`, `Reset`, and `Summary` actions.
4. Open the reference plugin settings page, cycle `Label`, toggle `Show Updated Marker`, and confirm the bar widget reflects the changes.
5. Set `Failure Mode` to `query`, re-run `!ref`, and confirm the plugin becomes `Degraded` with `E_LAUNCHER_QUERY`.
6. Use `Copy Diagnostics` and `Save Diagnostics`, then verify the exported payload shows `reference.local.toolkit` with degraded runtime metadata.
7. Set `Failure Mode` back to `none`, re-run `!ref`, and confirm the plugin returns to `Active`.
8. Repeat with `Failure Mode` set to `execute`, trigger an item, and confirm `E_LAUNCHER_EXECUTE`, then recover back to `none`.
9. Finish with `scripts/plugin-local.sh full` and `scripts/plugin-local.sh remove-reference`.
EOF
    ;;
  reference-export)
    cat <<EOF
Reference Plugin Diagnostics Export

Saved diagnostics directory:
  ${HOME}/.local/state/quickshell/plugin-diagnostics/

Reference fixtures:
  active export: ${reference_source_dir}/expected-diagnostics-active.json
  degraded export: ${reference_source_dir}/expected-diagnostics-degraded.json

Expected reference plugin id:
  ${reference_plugin_id}

Exported payload fields:
  schemaVersion
  generatedAt
  summary.installed
  summary.enabled
  summary.invalidManifests
  summary.statuses.{active,enabled,degraded,failed,disabled,validated,discovered,unknown}
  plugins[].{id,name,version,type,enabled,author,permissions,entryPoints,runtime}
  plugins[].runtime.{state,stateLabel,stateSeverity,code,codeLabel,codeSeverity,message,updatedAt}
  manifestErrors[]

Manual export actions:
  Settings -> Plugins -> Copy Diagnostics
  Settings -> Plugins -> Save Diagnostics
EOF
    ;;
  reference-status)
    target="${HOME}/.config/quickshell/plugins"
    check_only=0
    quiet=0
    silent_pass=0
    silent_status=0
    if [[ -n "${2:-}" && "${2:-}" != --* ]]; then
      target="$2"
      shift 2
    else
      shift 1
    fi
    while (($# > 0)); do
      case "$1" in
        --check)
          check_only=1
          ;;
        --quiet)
          quiet=1
          ;;
        --silent-pass)
          quiet=1
          silent_pass=1
          ;;
        --silent-status)
          quiet=1
          silent_status=1
          ;;
      esac
      shift
    done
    destination="${target}/${reference_dir_name}"
    health_failures=0
    if [[ -d "$reference_source_dir" ]]; then
      source_health="$(health_label 1 "reference plugin source")"
    else
      source_health="$(health_label 0 "reference plugin source")"
      health_failures=$((health_failures + 1))
    fi
    if [[ -f "$reference_state_fixture" && -f "$reference_settings_fixture" && -f "$reference_recovery_fixture" && -f "$reference_diag_active_fixture" && -f "$reference_diag_degraded_fixture" ]]; then
      fixture_health="$(health_label 1 "reference fixtures")"
    else
      fixture_health="$(health_label 0 "reference fixtures")"
      health_failures=$((health_failures + 1))
    fi
    if [[ -x "${script_dir}/check-plugin-reference-local.sh" && -x "${script_dir}/check-plugin-reference-contracts.sh" && -x "${script_dir}/check-plugin-reference-fixtures.sh" && -x "${script_dir}/check-plugin-reference-recovery.sh" && -x "${script_dir}/check-plugin-reference-diagnostics.sh" ]]; then
      guard_health="$(health_label 1 "reference guard scripts")"
    else
      guard_health="$(health_label 0 "reference guard scripts")"
      health_failures=$((health_failures + 1))
    fi
    if [[ -L "$destination" ]]; then
      install_target="$(readlink "$destination" || true)"
      if [[ "$install_target" == "$reference_source_dir" ]]; then
        install_health="$(health_label 1 "reference plugin installed as expected symlink")"
        install_state="installed (expected symlink)"
      else
        install_health="warning: reference plugin symlink target differs from repo-tracked source"
        install_state="installed (foreign symlink target)"
        health_failures=$((health_failures + 1))
      fi
    elif [[ -e "$destination" ]]; then
      install_health="warning: reference plugin path is present but not a symlink"
      install_state="present (non-symlink)"
      health_failures=$((health_failures + 1))
    else
      install_health="info: reference plugin not installed"
      install_state="not installed"
    fi
    if (( quiet == 0 )); then
      cat <<EOF
Reference Plugin Local Status

Install state:
  ${install_state}
  target path: ${destination}
  source path: ${reference_source_dir}
  plugin id: ${reference_plugin_id}

Health summary:
  ${source_health}
  ${fixture_health}
  ${guard_health}
  ${install_health}

Local commands:
  install:  scripts/plugin-local.sh install-reference ${target}
  smoke:    scripts/plugin-local.sh smoke-reference ${target}
  remove:   scripts/plugin-local.sh remove-reference ${target}
  quick:    scripts/plugin-local.sh quick
  full:     scripts/plugin-local.sh full
  flow:     scripts/plugin-local.sh reference-flow
  export:   scripts/plugin-local.sh reference-export

Reference fixtures:
  state:      ${reference_state_fixture}
  settings:   ${reference_settings_fixture}
  recovery:   ${reference_recovery_fixture}
  diag-active:${reference_diag_active_fixture}
  diag-degr.: ${reference_diag_degraded_fixture}

Reference guards:
  scripts/check-plugin-reference-local.sh
  scripts/check-plugin-reference-contracts.sh
  scripts/check-plugin-reference-fixtures.sh
  scripts/check-plugin-reference-recovery.sh
  scripts/check-plugin-reference-diagnostics.sh

Diagnostics export:
  saved path: ${HOME}/.local/state/quickshell/plugin-diagnostics/
  UI actions: Settings -> Plugins -> Copy Diagnostics / Save Diagnostics
EOF
    elif (( silent_status == 0 )); then
      printf '[INFO] Reference status: %s | %s | %s | %s\n' \
        "$source_health" \
        "$fixture_health" \
        "$guard_health" \
        "$install_health"
    fi
    if (( check_only == 1 )); then
      if (( health_failures == 0 )); then
        if (( silent_pass == 0 )); then
          printf '[INFO] Reference status check passed.\n'
        fi
      else
        printf '[FAIL] Reference status check failed: %d prerequisite issue(s).\n' "$health_failures" >&2
        exit 1
      fi
    fi
    ;;
  reference-files)
    cat <<EOF
source_dir=${reference_source_dir}
plugin_id=${reference_plugin_id}
state_fixture=${reference_state_fixture}
settings_fixture=${reference_settings_fixture}
recovery_fixture=${reference_recovery_fixture}
diagnostics_active_fixture=${reference_diag_active_fixture}
diagnostics_degraded_fixture=${reference_diag_degraded_fixture}
guard_local=${script_dir}/check-plugin-reference-local.sh
guard_contracts=${script_dir}/check-plugin-reference-contracts.sh
guard_fixtures=${script_dir}/check-plugin-reference-fixtures.sh
guard_recovery=${script_dir}/check-plugin-reference-recovery.sh
guard_diagnostics=${script_dir}/check-plugin-reference-diagnostics.sh
EOF
    ;;
  reference-guards)
    reference_guard_commands
    ;;
  reference-all)
    quiet=0
    silent_preflight=0
    if [[ "${2:-}" == "--quiet" ]]; then
      quiet=1
      if [[ "${3:-}" == "--silent-preflight" ]]; then
        silent_preflight=1
      fi
    elif [[ "${2:-}" == "--silent-preflight" ]]; then
      silent_preflight=1
    fi
    while IFS= read -r guard_cmd; do
      [[ -n "$guard_cmd" ]] || continue
      read -r -a guard_parts <<< "$guard_cmd"
      if (( quiet == 0 )); then
        printf '[INFO] Running %s...\n' "$(reference_guard_label "$guard_cmd")"
      fi
      "${guard_parts[@]}"
    done < <(reference_guard_commands "$quiet" "$silent_preflight")
    if (( quiet == 0 )); then
      printf '[INFO] Reference plugin checks passed.\n'
    fi
    ;;
  install-docker-manager)
    target="${2:-${HOME}/.config/quickshell/plugins}"
    destination="${target}/${docker_plugin_dir_name}"
    if [[ ! -d "$docker_source_dir" ]]; then
      echo "[FAIL] Missing docker-manager plugin source: ${docker_source_dir}" >&2
      exit 1
    fi
    mkdir -p "$target"
    if [[ -e "$destination" && ! -L "$destination" ]]; then
      echo "[FAIL] Refusing to overwrite non-symlink path: ${destination}" >&2
      exit 1
    fi
    if [[ -L "$destination" ]]; then
      current_target="$(readlink "$destination" || true)"
      if [[ "$current_target" == "$docker_source_dir" ]]; then
        printf '[INFO] Docker Manager plugin already linked at %s\n' "$destination"
        exit 0
      fi
      echo "[FAIL] Refusing to replace symlink with different target: ${destination}" >&2
      exit 1
    fi
    ln -s "$docker_source_dir" "$destination"
    printf '[INFO] Installed docker-manager plugin at %s\n' "$destination"
    ;;
  remove-docker-manager)
    target="${2:-${HOME}/.config/quickshell/plugins}"
    destination="${target}/${docker_plugin_dir_name}"
    if [[ ! -e "$destination" ]]; then
      printf '[INFO] Docker Manager plugin is not installed at %s\n' "$destination"
      exit 0
    fi
    if [[ ! -L "$destination" ]]; then
      echo "[FAIL] Refusing to remove non-symlink path: ${destination}" >&2
      exit 1
    fi
    current_target="$(readlink "$destination" || true)"
    if [[ "$current_target" != "$docker_source_dir" ]]; then
      echo "[FAIL] Refusing to remove symlink with different target: ${destination}" >&2
      exit 1
    fi
    rm "$destination"
    printf '[INFO] Removed docker-manager plugin from %s\n' "$destination"
    ;;
  smoke-docker-manager)
    target="${2:-${HOME}/.config/quickshell/plugins}"
    destination="${target}/${docker_plugin_dir_name}"
    manifest_path="${destination}/manifest.json"
    tmp_plugins="$(mktemp -d)"
    tmp_json="$(mktemp)"
    trap 'rm -rf "$tmp_plugins" "$tmp_json"' EXIT
    if [[ ! -f "$manifest_path" ]]; then
      echo "[FAIL] Docker Manager manifest not found: ${manifest_path}" >&2
      exit 1
    fi
    if ! jq -e --arg id "$docker_plugin_id" '.id == $id' "$manifest_path" >/dev/null 2>&1; then
      echo "[FAIL] Docker Manager manifest has unexpected id: ${manifest_path}" >&2
      exit 1
    fi
    if [[ ! -L "$destination" ]]; then
      echo "[FAIL] Docker Manager path is not the expected symlink: ${destination}" >&2
      exit 1
    fi
    current_target="$(readlink "$destination" || true)"
    if [[ "$current_target" != "$docker_source_dir" ]]; then
      echo "[FAIL] Docker Manager symlink has unexpected target: ${destination}" >&2
      exit 1
    fi
    cp -RL "$destination" "${tmp_plugins}/${docker_plugin_dir_name}"
    "${script_dir}/plugin-doctor.sh" --json "$tmp_plugins" > "$tmp_json"
    jq -e --arg name "$docker_plugin_dir_name" '
      .summary.fail == 0
      and .summary.pass == 1
      and ([.entries[] | select(.status == "PASS" and .name == $name)] | length) == 1
    ' "$tmp_json" >/dev/null 2>&1
    printf '[INFO] Docker Manager smoke passed for %s\n' "$destination"
    ;;
  docker-flow)
    cat <<'EOF'
Docker Manager Manual Flow

1. Run `scripts/plugin-local.sh install-docker-manager` and `scripts/plugin-local.sh smoke-docker-manager`.
2. Run `scripts/plugin-local.sh docker-all` to validate the local repo copy, runtime smoke harness, and contract checks.
3. Open Settings -> Plugins, confirm `Docker Manager` is present and enabled.
4. Add `Docker Manager` from the bar widget picker and confirm the badge appears in the bar.
5. Open the popup and confirm the running count and status text match `docker ps` on the machine.
6. Toggle compose view and port visibility, then reopen the popup and confirm those settings persist.
7. Change the runtime binary to an invalid command in plugin settings and confirm the plugin becomes degraded without crashing the bar.
8. Restore the runtime binary to `docker` and confirm the plugin returns to active state.
9. Finish with `scripts/plugin-local.sh remove-docker-manager` if you only needed a temporary local install.
EOF
    ;;
  docker-status)
    target="${HOME}/.config/quickshell/plugins"
    check_only=0
    quiet=0
    if [[ -n "${2:-}" && "${2:-}" != --* ]]; then
      target="$2"
      shift 2
    else
      shift 1
    fi
    while (($# > 0)); do
      case "$1" in
        --check)
          check_only=1
          ;;
        --quiet)
          quiet=1
          ;;
      esac
      shift
    done
    destination="${target}/${docker_plugin_dir_name}"
    health_failures=0
    if [[ -d "$docker_source_dir" && -f "$docker_manifest" && -f "$docker_readme" ]]; then
      source_health="$(health_label 1 "docker-manager plugin source")"
    else
      source_health="$(health_label 0 "docker-manager plugin source")"
      health_failures=$((health_failures + 1))
    fi
    if [[ -x "${script_dir}/check-plugin-docker-manager-local.sh" && -x "${script_dir}/check-plugin-docker-manager-runtime-smoke.sh" && -x "${script_dir}/check-plugin-docker-manager-contracts.sh" && -x "${script_dir}/check-plugin-docker-manager-diagnostics.sh" ]]; then
      guard_health="$(health_label 1 "docker-manager guard scripts")"
    else
      guard_health="$(health_label 0 "docker-manager guard scripts")"
      health_failures=$((health_failures + 1))
    fi
    if command -v quickshell >/dev/null 2>&1 && command -v docker >/dev/null 2>&1; then
      runtime_health="$(health_label 1 "quickshell and docker commands")"
    else
      runtime_health="$(health_label 0 "quickshell and docker commands")"
      health_failures=$((health_failures + 1))
    fi
    if docker info >/dev/null 2>&1; then
      daemon_health="$(health_label 1 "docker daemon reachable")"
    else
      daemon_health="$(health_label 0 "docker daemon reachable")"
      health_failures=$((health_failures + 1))
    fi
    if [[ -L "$destination" ]]; then
      install_target="$(readlink "$destination" || true)"
      if [[ "$install_target" == "$docker_source_dir" ]]; then
        install_health="$(health_label 1 "docker-manager plugin installed as expected symlink")"
        install_state="installed (expected symlink)"
      else
        install_health="warning: docker-manager plugin symlink target differs from repo-tracked source"
        install_state="installed (foreign symlink target)"
        health_failures=$((health_failures + 1))
      fi
    elif [[ -e "$destination" ]]; then
      install_health="warning: docker-manager plugin path is present but not a symlink"
      install_state="present (non-symlink)"
      health_failures=$((health_failures + 1))
    else
      install_health="info: docker-manager plugin not installed"
      install_state="not installed"
    fi
    if (( quiet == 0 )); then
      cat <<EOF
Docker Manager Local Status

Install state:
  ${install_state}
  target path: ${destination}
  source path: ${docker_source_dir}
  plugin id: ${docker_plugin_id}

Health summary:
  ${source_health}
  ${guard_health}
  ${runtime_health}
  ${daemon_health}
  ${install_health}

Local commands:
  install:  scripts/plugin-local.sh install-docker-manager ${target}
  smoke:    scripts/plugin-local.sh smoke-docker-manager ${target}
  remove:   scripts/plugin-local.sh remove-docker-manager ${target}
  status:   scripts/plugin-local.sh docker-status --check
  flow:     scripts/plugin-local.sh docker-flow
  all:      scripts/plugin-local.sh docker-all

Plugin files:
  manifest: ${docker_manifest}
  readme:   ${docker_readme}

Docker guards:
  scripts/check-plugin-docker-manager-local.sh
  scripts/check-plugin-docker-manager-runtime-smoke.sh
  scripts/check-plugin-docker-manager-contracts.sh
  scripts/check-plugin-docker-manager-diagnostics.sh
EOF
    else
      printf '[INFO] Docker Manager status: %s | %s | %s | %s | %s\n' \
        "$source_health" \
        "$guard_health" \
        "$runtime_health" \
        "$daemon_health" \
        "$install_health"
    fi
    if (( check_only == 1 )); then
      if (( health_failures == 0 )); then
        printf '[INFO] Docker Manager status check passed.\n'
      else
        printf '[FAIL] Docker Manager status check failed: %d prerequisite issue(s).\n' "$health_failures" >&2
        exit 1
      fi
    fi
    ;;
  docker-files)
    cat <<EOF
source_dir=${docker_source_dir}
plugin_id=${docker_plugin_id}
manifest=${docker_manifest}
readme=${docker_readme}
guard_local=${script_dir}/check-plugin-docker-manager-local.sh
guard_runtime_smoke=${script_dir}/check-plugin-docker-manager-runtime-smoke.sh
guard_contracts=${script_dir}/check-plugin-docker-manager-contracts.sh
guard_diagnostics=${script_dir}/check-plugin-docker-manager-diagnostics.sh
EOF
    ;;
  docker-guards)
    docker_guard_commands
    ;;
  docker-all)
    quiet=0
    if [[ "${2:-}" == "--quiet" ]]; then
      quiet=1
    fi
    while IFS= read -r guard_cmd; do
      [[ -n "$guard_cmd" ]] || continue
      read -r -a guard_parts <<< "$guard_cmd"
      if (( quiet == 0 )); then
        printf '[INFO] Running %s...\n' "$(docker_guard_label "$guard_cmd")"
      fi
      "${guard_parts[@]}"
    done < <(docker_guard_commands)
    if (( quiet == 0 )); then
      printf '[INFO] Docker Manager plugin checks passed.\n'
    fi
    ;;
  quickshell-flow)
    cat <<EOF
Quickshell Manual Flow

1. Ensure the current Home Manager generation is active:
   - home-manager switch --flake /home/administrator/nixos-config#administrator@woody
2. Run the focused Quickshell runtime checks:
   - scripts/check-quickshell-startup.sh
   - scripts/check-panel-runtime.sh --repo-shell
3. Run the assembled Quickshell workflow:
   - scripts/plugin-local.sh quickshell-all
EOF
    ;;
  quickshell-status)
    check_only=0
    quiet=0
    shift 1
    while (($# > 0)); do
      case "$1" in
        --check)
          check_only=1
          ;;
        --quiet)
          quiet=1
          ;;
      esac
      shift
    done
    health_failures=0
    if [[ -f "$shell_config" ]]; then
      shell_health="$(health_label 1 "quickshell shell config")"
    else
      shell_health="$(health_label 0 "quickshell shell config")"
      health_failures=$((health_failures + 1))
    fi
    if [[ -x "${script_dir}/check-quickshell-startup.sh" && -x "${script_dir}/check-settings-responsive.sh" && -x "${script_dir}/check-surface-responsive.sh" && -x "${script_dir}/check-panel-runtime.sh" ]]; then
      guard_health="$(health_label 1 "quickshell runtime guard scripts")"
    else
      guard_health="$(health_label 0 "quickshell runtime guard scripts")"
      health_failures=$((health_failures + 1))
    fi
    if command -v systemctl >/dev/null 2>&1; then
      if systemctl --user is-active --quiet quickshell.service; then
        service_health="$(health_label 1 "quickshell.service active")"
      else
        service_health="$(health_label 1 "repo-shell runtime path available")"
      fi
    else
      service_health="$(health_label 0 "repo-shell runtime path available")"
      health_failures=$((health_failures + 1))
    fi
    if (( quiet == 0 )); then
      cat <<EOF
Quickshell Runtime Status

Shell state:
  config: ${shell_config}
  service: quickshell.service

Health summary:
  ${shell_health}
  ${guard_health}
  ${service_health}

Local commands:
  flow:    scripts/plugin-local.sh quickshell-flow
  status:  scripts/plugin-local.sh quickshell-status --check
  guards:  scripts/plugin-local.sh quickshell-guards
  all:     scripts/plugin-local.sh quickshell-all

Runtime files:
  startup:  ${script_dir}/check-quickshell-startup.sh
  panel:    ${script_dir}/check-panel-runtime.sh --repo-shell
EOF
    else
      printf '[INFO] Quickshell status: %s | %s | %s\n' \
        "$shell_health" \
        "$guard_health" \
        "$service_health"
    fi
    if (( check_only == 1 )); then
      if (( health_failures == 0 )); then
        printf '[INFO] Quickshell status check passed.\n'
      else
        printf '[FAIL] Quickshell status check failed: %d prerequisite issue(s).\n' "$health_failures" >&2
        exit 1
      fi
    fi
    ;;
  quickshell-files)
    cat <<EOF
shell_config=${shell_config}
guard_startup=${script_dir}/check-quickshell-startup.sh
guard_settings=${script_dir}/check-settings-responsive.sh
guard_surfaces=${script_dir}/check-surface-responsive.sh
guard_panel_runtime=${script_dir}/check-panel-runtime.sh
service_name=quickshell.service
EOF
    ;;
  quickshell-guards)
    quickshell_guard_commands
    ;;
  quickshell-all)
    quiet=0
    if [[ "${2:-}" == "--quiet" ]]; then
      quiet=1
    fi
    while IFS= read -r guard_cmd; do
      [[ -n "$guard_cmd" ]] || continue
      read -r -a guard_parts <<< "$guard_cmd"
      if (( quiet == 0 )); then
        printf '[INFO] Running %s...\n' "$(quickshell_guard_label "$guard_cmd")"
      fi
      "${guard_parts[@]}"
    done < <(quickshell_guard_commands)
    if (( quiet == 0 )); then
      printf '[INFO] Quickshell runtime checks passed.\n'
    fi
    ;;
  live-gates)
    quiet=0
    if [[ "${2:-}" == "--quiet" ]]; then
      quiet=1
    fi
    if (( quiet == 0 )); then
      printf '[INFO] Running shared plugin/runtime gates...\n'
      "${script_dir}/plugin-local.sh" shared-gates
      printf '[INFO] Running live Quickshell runtime gates...\n'
      "${script_dir}/plugin-local.sh" quickshell-all
      printf '[INFO] Live Quickshell gates passed.\n'
    else
      "${script_dir}/plugin-local.sh" shared-gates --quiet
      "${script_dir}/plugin-local.sh" quickshell-all --quiet
    fi
    ;;
  shared-gates)
    quiet=0
    if [[ "${2:-}" == "--quiet" ]]; then
      quiet=1
    fi
    if (( quiet == 0 )); then
      printf '[INFO] Running Quickshell startup smoke checks...\n'
    fi
    "${script_dir}/check-quickshell-startup.sh"
    if (( quiet == 0 )); then
      printf '[INFO] Running plugin runtime guard checks...\n'
    fi
    "${script_dir}/check-plugin-runtime-guards.sh"
    if (( quiet == 0 )); then
      printf '[INFO] Running plugin diagnostics contract checks...\n'
    fi
    "${script_dir}/check-plugin-diagnostics-contracts.sh"
    if (( quiet == 0 )); then
      printf '[INFO] Running plugin diagnostics schema sync checks...\n'
    fi
    "${script_dir}/sync-plugin-diagnostics-schema.sh" --check
    if (( quiet == 0 )); then
      printf '[INFO] Running plugin diagnostics schema checks...\n'
    fi
    "${script_dir}/check-plugin-diagnostics-schema.sh"
    ;;
  baseline-gates)
    quiet=0
    if [[ "${2:-}" == "--quiet" ]]; then
      quiet=1
    fi
    if (( quiet == 0 )); then
      printf '[INFO] Running plugin conformance checks...\n'
    fi
    "${script_dir}/check-plugin-conformance.sh"
    if (( quiet == 0 )); then
      printf '[INFO] Running docker-manager plugin contract checks...\n'
    fi
    "${script_dir}/check-plugin-docker-manager-contracts.sh"
    if (( quiet == 0 )); then
      printf '[INFO] Running plugin doctor smoke checks...\n'
    fi
    "${script_dir}/check-plugin-doctor-smoke.sh"
    ;;
  all-gates)
    quiet=0
    if [[ "${2:-}" == "--quiet" ]]; then
      quiet=1
    fi
    if (( quiet == 0 )); then
      printf '[INFO] Running baseline plugin gates...\n'
    fi
    if (( quiet == 0 )); then
      "${script_dir}/plugin-local.sh" baseline-gates
    else
      "${script_dir}/plugin-local.sh" baseline-gates --quiet
    fi
    if (( quiet == 0 )); then
      printf '[INFO] Running plugin reference toolkit checks...\n'
      "${script_dir}/plugin-local.sh" reference-all
      if "${script_dir}/plugin-local.sh" docker-status --check >/dev/null 2>&1; then
        printf '[INFO] Running docker-manager plugin checks...\n'
        "${script_dir}/plugin-local.sh" docker-all
      else
        printf '[INFO] Skipping docker-manager plugin checks; run `scripts/plugin-local.sh docker-status` for details.\n'
      fi
      printf '[INFO] Running shared plugin gates...\n'
      "${script_dir}/plugin-local.sh" shared-gates
      printf '[INFO] Plugin verification passed.\n'
    else
      "${script_dir}/plugin-local.sh" reference-all --quiet --silent-preflight
      if "${script_dir}/plugin-local.sh" docker-status --check >/dev/null 2>&1; then
        "${script_dir}/plugin-local.sh" docker-all --quiet
      fi
      "${script_dir}/plugin-local.sh" shared-gates --quiet
    fi
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "[FAIL] Unknown mode: $mode" >&2
    usage >&2
    exit 2
    ;;
esac
