#!/usr/bin/env bash
# Monitors systemd-logind PrepareForSleep signal via dbus-monitor.
# Emits "SUSPEND" or "WAKE" lines on stdout for the QML Process to consume.
# Auto-restarts on dbus-monitor failure.

while true; do
  dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" 2>/dev/null \
    | while IFS= read -r line; do
        case "$line" in
          *"boolean true"*)  echo "SUSPEND" ;;
          *"boolean false"*) echo "WAKE" ;;
        esac
      done
  # dbus-monitor exited unexpectedly — wait before retrying
  sleep 2
done
