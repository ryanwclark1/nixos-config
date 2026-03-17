#!/usr/bin/env bash
set -euo pipefail

config_root="$(pwd)/config"

check_file() {
  local file="$1"
  echo "Checking $file..."
  local log_file="check_$(basename "$file").log"
  QT_QPA_PLATFORM=offscreen timeout 5s quickshell -p "$file" >"$log_file" 2>&1 || true
  if grep -E "ERROR|TypeError|ReferenceError|is not a type" "$log_file"; then
    echo "Errors found in $file:"
    grep -E "ERROR|TypeError|ReferenceError|is not a type" "$log_file"
  else
    echo "$file seems to load OK (or at least no immediate errors)."
  fi
  rm -f "$log_file"
}

check_file "${config_root}/widgets/InnerHighlight.qml"
check_file "${config_root}/widgets/CardBase.qml"
check_file "${config_root}/modules/ProcessWidget.qml"
check_file "${config_root}/menu/ControlCenter.qml"
check_file "${config_root}/menu/SettingsHub.qml"
