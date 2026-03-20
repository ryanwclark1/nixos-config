#!/usr/bin/env bash

known_quickshell_harness_warning_pattern() {
  cat <<'EOF'
^(No running instances for |  WARN: <Unknown File>: QML ProxyFloatingWindow: Setting `(width|height)` is deprecated\. Set `(implicitWidth|implicitHeight)` instead\.|  WARN: Unable to find hyprland socket\. Cannot connect to hyprland\.|  WARN quickshell\.hyprland\.ipc: Error making request: QLocalSocket::ServerNotFoundError request: "j/clients"|  WARN: This plugin does not support setting window masks|  INFO: Launching config: |  INFO: Shell ID: |  INFO: Saving logs to |  INFO: Configuration Loaded$)
EOF
}

strip_ansi_escape_sequences() {
  local input="${1-}"
  printf '%s\n' "${input}" | sed -E $'s/\x1B\\[[0-9;]*[[:alpha:]]//g'
}

filter_known_quickshell_harness_warnings() {
  local output="${1-}"
  strip_ansi_escape_sequences "${output}" | grep -Ev "$(known_quickshell_harness_warning_pattern)"
}

fail_on_quickshell_harness_warnings() {
  local harness_name="${1:?missing harness name}"
  local output="${2-}"
  local filtered_output="${3-}"
  local normalized_output=""

  normalized_output="$(strip_ansi_escape_sequences "${output}")"

  if grep -q 'TypeError:' <<<"${normalized_output}"; then
    printf '[FAIL] %s emitted QML TypeError warnings.\n' "${harness_name}" >&2
    exit 1
  fi

  if [[ -n "${filtered_output}" ]] && printf '%s\n' "${filtered_output}" | grep -Eqi '(^|[[:space:]])(warn(ing)?|error|exception|failed)\b|binding loop|ReferenceError|TypeError'; then
    printf '[FAIL] %s emitted unexpected warnings/errors.\n' "${harness_name}" >&2
    printf '%s\n' "${filtered_output}" >&2
    exit 1
  fi
}
