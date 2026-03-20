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
libpng error: Read Error
\[W\]\[WeatherService\] Error: empty weather response
\[W\]\[MarketService\] Error: empty market response
EOF

  case "${profile}" in
    settings)
      cat <<'EOF'
quickshell\.dbus\.objectmanager: Failed to create DBusObjectManagerInterface for "org\.bluez" "/" : QDBusError\("", ""\)
QML QQuickItem at qrc:/qt/qml/Quickshell/Widgets/ClippingRectangle\.qml\[68:3\]: Wrapper component cannot have more than one visual child\.
QML QQuickItem at qrc:/qt/qml/Quickshell/Widgets/ClippingRectangle\.qml\[68:3\]: Remove all additional children, or pick a specific component to wrap using the child property\.
qs:@/qs/bar/Panel\.qml:514:13: QML QQuickItem\*: Binding loop detected for property "height"
\[W\]\[SystemStatus\] helper scripts not executable \(set QS_SCRIPT_ROOT to override .*/quickshell/scripts\) exitCode=1 exitStatus=0
Layershell screen does not corrospond to a real screen\. Letting the compositor pick\.
\[W\]\[WeatherService\] Error: missing current condition
quickshell\.io\.fileview: got operation finished from dropped operation qs::io::FileViewOperation\(.*\)
EOF
      ;;
    surfaces|targeted-surfaces)
      cat <<'EOF'
Layershell screen does not corrospond to a real screen\. Letting the compositor pick\.
EOF
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
    sed -E $'s/\x1B\\[[0-9;]*[[:alpha:]]//g' "${input_file}" | grep -Evi "${pattern}" || true
  else
    sed -E $'s/\x1B\\[[0-9;]*[[:alpha:]]//g' "${input_file}"
  fi
}

runtime_log_contains_actionable_text() {
  local log_text="${1:-}"
  [[ -n "${log_text}" ]] || return 1
  printf '%s' "${log_text}" | grep -Eqi 'warn|error|exception|binding loop|ReferenceError|TypeError|failed'
}
