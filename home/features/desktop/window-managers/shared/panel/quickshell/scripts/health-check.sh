#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
repo_root="${QS_REPO_ROOT:-$(CDPATH= cd -- "${script_dir}/.." >/dev/null 2>&1 && pwd -P)}"
rules_file="${QS_HEALTH_RULES_FILE:-${script_dir}/health-rules.json}"
compositor_guard_script="${QS_COMPOSITOR_GUARD_SCRIPT:-${script_dir}/check-compositor-guards.sh}"
compositor_fixture_script="${QS_COMPOSITOR_FIXTURE_SCRIPT:-${script_dir}/check-compositor-fixtures.sh}"
compositor_verify_script="${QS_COMPOSITOR_VERIFY_SCRIPT:-${script_dir}/compositor-verify.sh}"
compositor_smoke_script="${QS_COMPOSITOR_SMOKE_SCRIPT:-${script_dir}/compositor-smoke.sh}"
health_safe_fix_script="${QS_HEALTH_SAFE_FIX_SCRIPT:-${script_dir}/health-safe-fix.sh}"
state_root="${QS_HEALTH_STATE_ROOT:-${XDG_STATE_HOME:-${HOME}/.local/state}/quickshell}"
incident_root="${state_root}/incidents"
index_file="${incident_root}/index.json"
apply_safe_fixes=0
dry_run=0
since_window="15 minutes ago"
summary_status=0
safe_fix_attempted=0
safe_fix_succeeded=0
declare -a active_signatures=()

usage() {
  cat <<'EOF'
Usage: health-check.sh [--apply-safe-fixes] [--dry-run] [--since WINDOW]

Exit codes:
  0   healthy or safe-fix resolved
  10  safe-fixable issue detected but not resolved
  20  manual-review issue detected
  30  detector/runtime failure
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 30
  fi
}

rule_field() {
  local signature="$1"
  local field="$2"
  jq -r --arg signature "${signature}" --arg field "${field}" '
    map(select(.signature == $signature)) | .[0][$field] // empty
  ' "${rules_file}"
}

signatures_json() {
  if (( ${#active_signatures[@]} == 0 )); then
    printf '[]\n'
  else
    printf '%s\n' "${active_signatures[@]}" | jq -R . | jq -s .
  fi
}

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9._-' '-'
}

ensure_incident_store() {
  mkdir -p "${incident_root}"
  if [[ ! -s "${index_file}" ]] || ! jq -e 'type == "object"' "${index_file}" >/dev/null 2>&1; then
    printf '{}\n' > "${index_file}"
  fi
}

incident_dir_for_signature() {
  local signature="$1"
  local dir
  dir="$(jq -r --arg signature "${signature}" '.[$signature] // empty' "${index_file}" 2>/dev/null)" || dir=""
  if [[ -n "${dir}" && -d "${dir}" ]]; then
    printf '%s\n' "${dir}"
    return 0
  fi

  dir="${incident_root}/$(date -u +%Y%m%dT%H%M%SZ)-$(slugify "${signature}")"
  mkdir -p "${dir}"
  local tmp_index
  tmp_index="$(mktemp)"
  if jq --arg signature "${signature}" --arg dir "${dir}" '.[$signature] = $dir' "${index_file}" > "${tmp_index}" 2>/dev/null \
     && [[ -s "${tmp_index}" ]]; then
    mv "${tmp_index}" "${index_file}"
  else
    # Index was unreadable; rebuild from this single entry
    printf '{%s:%s}\n' "$(printf '%s' "${signature}" | jq -Rs .)" "$(printf '%s' "${dir}" | jq -Rs .)" > "${tmp_index}"
    mv "${tmp_index}" "${index_file}"
  fi
  printf '%s\n' "${dir}"
}

write_environment_snapshot() {
  local dir="$1"
  local active_state exec_pid restart_count
  active_state="$(systemctl --user is-active quickshell.service 2>/dev/null || true)"
  exec_pid="$(systemctl --user show quickshell.service -P ExecMainPID 2>/dev/null || true)"
  restart_count="$(systemctl --user show quickshell.service -P NRestarts 2>/dev/null || true)"
  jq -n \
    --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg host "$(hostname 2>/dev/null || true)" \
    --arg repo_root "${repo_root}" \
    --arg session_type "${XDG_SESSION_TYPE:-}" \
    --arg current_desktop "${XDG_CURRENT_DESKTOP:-}" \
    --arg wayland_display "${WAYLAND_DISPLAY:-}" \
    --arg quickshell_state "${active_state}" \
    --arg quickshell_pid "${exec_pid}" \
    --arg quickshell_restarts "${restart_count}" \
    '{
      generated_at: $generated_at,
      host: $host,
      repo_root: $repo_root,
      session_type: $session_type,
      current_desktop: $current_desktop,
      wayland_display: $wayland_display,
      quickshell_service_state: $quickshell_state,
      quickshell_pid: $quickshell_pid,
      quickshell_restart_count: $quickshell_restarts
    }' > "${dir}/environment.json"
}

write_fix_plan() {
  local dir="$1"
  local signature="$2"
  local description repro
  description="$(rule_field "${signature}" description)"
  repro="$(rule_field "${signature}" repro)"
  cat > "${dir}/fix-plan.md" <<EOF
# ${signature}

${description}

## Repro
\`\`\`bash
${repro}
\`\`\`
EOF
}

record_incident() {
  local signature="$1"
  local status="$2"
  local summary="$3"
  local evidence_file="$4"
  local safe_fix_id="$5"
  local requested_evidence_name="${6:-}"
  local dir count severity repro evidence_name

  active_signatures+=("${signature}")
  dir="$(incident_dir_for_signature "${signature}")"
  severity="$(rule_field "${signature}" severity)"
  repro="$(rule_field "${signature}" repro)"
  count="$(jq -r '.count // 0' "${dir}/incident.json" 2>/dev/null || printf '0')"
  count=$((count + 1))
  if [[ -n "${requested_evidence_name}" ]]; then
    evidence_name="${requested_evidence_name}"
  else
    evidence_name="$(basename "${evidence_file}")"
  fi

  cp "${evidence_file}" "${dir}/${evidence_name}"
  write_environment_snapshot "${dir}"
  if [[ -z "${safe_fix_id}" ]]; then
    write_fix_plan "${dir}" "${signature}"
  fi

  jq -n \
    --arg id "$(basename "${dir}")" \
    --arg signature "${signature}" \
    --arg severity "${severity}" \
    --arg status "${status}" \
    --arg summary "${summary}" \
    --arg safe_fix_id "${safe_fix_id}" \
    --arg repro "${repro}" \
    --arg first_seen "$(jq -r '.first_seen // empty' "${dir}/incident.json" 2>/dev/null || true)" \
    --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --argjson count "${count}" \
    '{
      id: $id,
      signature: $signature,
      severity: $severity,
      status: $status,
      summary: $summary,
      safe_fix_available: ($safe_fix_id != ""),
      safe_fix_id: (if $safe_fix_id == "" then null else $safe_fix_id end),
      auto_fix_attempted: false,
      auto_fix_succeeded: false,
      count: $count,
      first_seen: (if $first_seen == "" then $now else $first_seen end),
      last_seen: $now,
      repro: $repro,
      artifacts: [
        "environment.json",
        $evidence_name
      ]
    }' \
    --arg evidence_name "${evidence_name}" > "${dir}/incident.json"

  printf '%s\n' "${dir}"
}

update_incident_fix_status() {
  local dir="$1"
  local status="$2"
  local succeeded="$3"
  local patch_name="${4:-}"
  local tmp
  tmp="$(mktemp)"
  jq \
    --arg status "${status}" \
    --argjson succeeded "${succeeded}" \
    --arg patch_name "${patch_name}" \
    '.status = $status
     | .auto_fix_attempted = true
     | .auto_fix_succeeded = $succeeded
     | .last_seen = (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
     | .artifacts = (.artifacts + (if $patch_name == "" then [] else [$patch_name] end) | unique)' \
    "${dir}/incident.json" > "${tmp}"
  mv "${tmp}" "${dir}/incident.json"
}

resolve_inactive_incidents() {
  local existing signature dir tmp
  mapfile -t existing < <(jq -r 'keys[]?' "${index_file}" 2>/dev/null)
  for signature in "${existing[@]}"; do
    [[ -n "${signature}" ]] || continue
    if (( ${#active_signatures[@]} > 0 )) \
       && printf '%s\n' "${active_signatures[@]}" | rg -qx -- "${signature}"; then
      continue
    fi
    dir="$(jq -r --arg signature "${signature}" '.[$signature] // empty' "${index_file}" 2>/dev/null)" || dir=""
    tmp="$(mktemp)"
    if jq --arg signature "${signature}" 'del(.[$signature])' "${index_file}" > "${tmp}" 2>/dev/null \
       && [[ -s "${tmp}" ]]; then
      mv "${tmp}" "${index_file}"
    else
      rm -f "${tmp}"
    fi
    # Delete the directory only after the index entry is removed, so a crash
    # between the two operations leaves a resolvable (not orphaned) state.
    if [[ -n "${dir}" && -d "${dir}" ]]; then
      rm -rf "${dir}"
    fi
  done
}

discover_instance() {
  local runtime_root="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/quickshell/by-id"
  local candidate
  if [[ ! -d "${runtime_root}" ]]; then
    return 1
  fi
  while IFS= read -r candidate; do
    [[ -n "${candidate}" ]] || continue
    if quickshell ipc --id "${candidate}" show >/dev/null 2>&1; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done < <(find "${runtime_root}" -mindepth 1 -maxdepth 1 -type d -exec test -S '{}/ipc.sock' ';' -printf '%f\n' 2>/dev/null | sort)
  return 1
}

run_probe_step() {
  local log_file="$1"
  shift
  {
    printf '$ %s\n' "$*"
    "$@"
  } >> "${log_file}" 2>&1
}

run_surface_probes() {
  local instance_id="$1"
  local settings_log="$2"
  local controls_log="$3"
  local notifications_log="$4"

  : > "${settings_log}"
  : > "${controls_log}"
  : > "${notifications_log}"

  # Visual IPC probes removed as they annoyingly cycle on the user's screen
  # every time the health check runs.

  return 0
}

apply_safe_fix_if_allowed() {
  local signature="$1"
  local dir="$2"
  local safe_fix_id="$3"
  local patch_file

  if (( dry_run == 1 || apply_safe_fixes == 0 )); then
    summary_status=10
    return 0
  fi

  safe_fix_attempted=1
  patch_file="${dir}/applied-fix.patch"
  if "${health_safe_fix_script}" "${safe_fix_id}" > "${dir}/safe-fix.log" 2>&1; then
    git -C "${repo_root}" diff -- \
      home/features/desktop/window-managers/shared/panel/quickshell/scripts/check-compositor-guards.sh \
      home/features/desktop/window-managers/shared/panel/quickshell/scripts/check-compositor-fixtures.sh \
      home/features/desktop/window-managers/shared/panel/quickshell/scripts/compositor-verify.sh \
      home/features/desktop/window-managers/shared/panel/quickshell/scripts/compositor-smoke.sh > "${patch_file}" || true
    safe_fix_succeeded=1
    update_incident_fix_status "${dir}" "resolved_by_automation" true "$(basename "${patch_file}")"
  else
    summary_status=10
    update_incident_fix_status "${dir}" "safe_fix_failed" false ""
  fi
}

main() {
  local guard_log fixture_log journal_log safe_fix_probe_log static_failure_log
  local settings_probe_log controls_probe_log notifications_probe_log
  local service_state instance_id count threshold pattern signature dir safe_fix_id probe_rc

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --apply-safe-fixes)
        apply_safe_fixes=1
        shift
        ;;
      --dry-run)
        dry_run=1
        shift
        ;;
      --since)
        since_window="${2:-}"
        shift 2
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

  require_cmd jq
  require_cmd rg
  require_cmd systemctl
  require_cmd journalctl
  require_cmd quickshell
  ensure_incident_store

  guard_log="$(mktemp)"
  fixture_log="$(mktemp)"
  journal_log="$(mktemp)"
  safe_fix_probe_log="$(mktemp)"
  static_failure_log="$(mktemp)"
  settings_probe_log="$(mktemp)"
  controls_probe_log="$(mktemp)"
  notifications_probe_log="$(mktemp)"
  trap 'rm -f "${guard_log}" "${fixture_log}" "${journal_log}" "${safe_fix_probe_log}" "${static_failure_log}" "${settings_probe_log}" "${controls_probe_log}" "${notifications_probe_log}"' EXIT

  local repo_scripts_dir="${repo_root}/home/features/desktop/window-managers/shared/panel/quickshell/scripts"
  if [[ -d "${repo_scripts_dir}" ]]; then
    {
      printf 'Checking repo-owned quickshell scripts for legacy script_dir pattern...\n'
      rg -n -F 'script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"' \
        "${repo_scripts_dir}/check-compositor-guards.sh" \
        "${repo_scripts_dir}/check-compositor-fixtures.sh" \
        "${repo_scripts_dir}/compositor-verify.sh" \
        "${repo_scripts_dir}/compositor-smoke.sh" || true
    } > "${safe_fix_probe_log}"
  fi

  if rg -q '^[^:]+:' "${safe_fix_probe_log}"; then
    signature="legacy-script-dir-resolution"
    safe_fix_id="$(rule_field "${signature}" safe_fix_id)"
    dir="$(record_incident "${signature}" "open" "Legacy quickshell script_dir pattern detected." "${safe_fix_probe_log}" "${safe_fix_id}" "safe-fix-probe.log")"
    apply_safe_fix_if_allowed "${signature}" "${dir}" "${safe_fix_id}"
  fi

  if ! bash "${compositor_guard_script}" > "${guard_log}" 2>&1; then
    cat "${guard_log}" > "${static_failure_log}"
  fi
  if ! bash "${compositor_fixture_script}" > "${fixture_log}" 2>&1; then
    cat "${fixture_log}" >> "${static_failure_log}"
  fi
  if [[ -s "${static_failure_log}" ]]; then
    signature="compositor-static-check-failed"
    record_incident "${signature}" "open" "Compositor guard or fixture checks failed." "${static_failure_log}" "" "compositor-static.log" >/dev/null
    summary_status=20
  fi

  service_state="$(systemctl --user is-active quickshell.service 2>/dev/null || true)"
  if [[ "${since_window}" == "15 minutes ago" && "${service_state}" == "active" ]]; then
    service_started_at="$(systemctl --user show quickshell.service -P ActiveEnterTimestamp 2>/dev/null || true)"
    if [[ -n "${service_started_at}" ]]; then
      since_window="${service_started_at}"
    fi
  fi
  if [[ "${service_state}" != "active" ]]; then
    printf 'quickshell.service state: %s\n' "${service_state}" > "${static_failure_log}"
    record_incident "quickshell-service-inactive" "open" "quickshell.service is not active." "${static_failure_log}" "" "service-status.log" >/dev/null
    summary_status=20
  else
    if ! instance_id="$(discover_instance)"; then
      printf 'quickshell.service is active but no reachable IPC instance was found.\n' > "${static_failure_log}"
      record_incident "quickshell-ipc-unreachable" "open" "No reachable quickshell IPC socket was found." "${static_failure_log}" "" "ipc.log" >/dev/null
      summary_status=20
    else
      run_surface_probes "${instance_id}" "${settings_probe_log}" "${controls_probe_log}" "${notifications_probe_log}" || probe_rc=$?
      if (( ${probe_rc:-0} != 0 )); then
        case "${probe_rc}" in
          11)
            record_incident "quickshell-settings-probe-failed" "open" "SettingsHub IPC probe failed." "${settings_probe_log}" "" "settings-probe.log" >/dev/null
            ;;
          12)
            record_incident "quickshell-control-center-probe-failed" "open" "Control center IPC probe failed." "${controls_probe_log}" "" "control-center-probe.log" >/dev/null
            ;;
          13)
            record_incident "quickshell-notification-center-probe-failed" "open" "Notification center IPC probe failed." "${notifications_probe_log}" "" "notification-center-probe.log" >/dev/null
            ;;
        esac
        summary_status=20
      fi
    fi
  fi

  journalctl --user -u quickshell --since "${since_window}" --no-pager > "${journal_log}" 2>&1 || true
  while IFS= read -r signature; do
    [[ -n "${signature}" ]] || continue
    pattern="$(rule_field "${signature}" pattern)"
    threshold="$(rule_field "${signature}" threshold)"
    [[ -n "${pattern}" ]] || continue
    count="$(rg -c -e "${pattern}" "${journal_log}" || true)"
    count="${count:-0}"
    if (( count >= threshold )); then
      record_incident "${signature}" "open" "Matched ${count} journal entries for ${signature}." "${journal_log}" "" "journal.log" >/dev/null
      summary_status=20
    fi
  done < <(jq -r '.[] | select(.kind == "journal") | .signature' "${rules_file}")

  resolve_inactive_incidents

  jq -n \
    --arg status "$(case "${summary_status}" in 0) printf 'healthy' ;; 10) printf 'safe_fix_pending' ;; 20) printf 'manual_review_required' ;; *) printf 'detector_failed' ;; esac)" \
    --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg since_window "${since_window}" \
    --argjson safe_fix_attempted "${safe_fix_attempted}" \
    --argjson safe_fix_succeeded "${safe_fix_succeeded}" \
    --argjson active_signatures "$(signatures_json)" \
    '{
      generated_at: $now,
      status: $status,
      since_window: $since_window,
      safe_fix_attempted: $safe_fix_attempted,
      safe_fix_succeeded: $safe_fix_succeeded,
      active_signatures: $active_signatures
    }'

  exit "${summary_status}"
}

main "$@"
