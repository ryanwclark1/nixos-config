#!/usr/bin/env bash

set -euo pipefail

restart_services() {
  if systemctl --user is-enabled elephant.service &>/dev/null; then
    systemctl --user restart elephant.service
  fi

  if systemctl --user is-enabled app-walker@autostart.service &>/dev/null; then
    systemctl --user restart app-walker@autostart.service
  else
    echo -e "\e[31mUnable to restart Walker -- RESTART MANUALLY\e[0m"
  fi
}

# Detect if we're running as root (from pacman hook)
if [[ $EUID -eq 0 ]]; then
  # Get the owner of this script to determine which user to run as
  SCRIPT_OWNER=$(stat -c '%U' "$0")
  USER_UID=$(id -u "$SCRIPT_OWNER")

  # Restart services as the script owner
  systemd-run --uid="$SCRIPT_OWNER" --setenv=XDG_RUNTIME_DIR="/run/user/$USER_UID" \
    bash -c "$(declare -f restart_services); restart_services"
else
  restart_services
fi
