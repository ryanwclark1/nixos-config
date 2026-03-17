#!/usr/bin/env bash
set -euo pipefail

config_root="$(pwd)/config"
log_file="$(pwd)/quickshell_runtime.log"

# Clean up any existing log
rm -f "${log_file}"

# Run quickshell in background with headless platform
QT_QPA_PLATFORM=offscreen quickshell -p "${config_root}/shell.qml" >"${log_file}" 2>&1 &
qs_pid=$!

# Wait for startup
sleep 3

# Check if it started correctly
if ! kill -0 "${qs_pid}" 2>/dev/null; then
  echo "Quickshell failed to start."
  cat "${log_file}"
  exit 1
fi

echo "Triggering Control Center..."
quickshell ipc --newest call Shell toggleControls || true

sleep 1

echo "Triggering Settings..."
quickshell ipc --newest call SettingsHub open || true

sleep 2

# Kill quickshell
kill "${qs_pid}" || true
wait "${qs_pid}" || true

echo "--- Log Content ---"
cat "${log_file}"
