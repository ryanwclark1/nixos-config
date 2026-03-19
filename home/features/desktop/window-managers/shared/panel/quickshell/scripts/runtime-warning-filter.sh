#!/usr/bin/env bash

runtime_warning_ignore_patterns() {
  local profile="${1:-default}"

  cat <<'EOF'
qt\.qpa\.wayland\.textinput
qt\.svg: .*Could not resolve property
Could not register notification server
Registration will be attempted again
quickshell\.hyprland\.ipc: Got removal for workspace id .* which was not previously tracked\.
QML QQuickImage at @features/clipboard/ClipboardMenu\.qml\[.*\]: Error decoding: file:///run/user/.*/quickshell-clipboard/.*
EOF

  case "${profile}" in
    surfaces|targeted-surfaces)
      ;;
  esac
}

runtime_filter_log_delta() {
  local profile="${1:-default}"
  local input_file="${2:-}"
  local pattern=""
  local line=""

  [[ -n "${input_file}" && -f "${input_file}" ]] || return 0

  while IFS= read -r line; do
    [[ -n "${line}" ]] || continue
    if [[ -n "${pattern}" ]]; then
      pattern="${pattern}|${line}"
    else
      pattern="${line}"
    fi
  done < <(runtime_warning_ignore_patterns "${profile}")

  if [[ -n "${pattern}" ]]; then
    grep -Evi "${pattern}" "${input_file}" || true
  else
    cat "${input_file}"
  fi
}

runtime_log_contains_actionable_text() {
  local log_text="${1:-}"
  [[ -n "${log_text}" ]] || return 1
  printf '%s' "${log_text}" | grep -Eqi 'warn|error|exception|binding loop|ReferenceError|TypeError|failed'
}
