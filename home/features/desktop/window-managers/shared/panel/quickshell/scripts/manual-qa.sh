#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
repo_root="$(CDPATH= cd -- "${script_dir}/.." >/dev/null && pwd)"
checklist_path="${repo_root}/MANUAL_QA_CHECKLIST.md"

usage() {
  cat <<EOF
Usage: manual-qa.sh [--checklist] [--journal] [--settings] [--surfaces] [--launcher] [--artifacts] [--all]

Helpers for the remaining manual Quickshell QA pass.

Options:
  --checklist  Print the manual QA checklist path and contents.
  --journal    Print the recommended journal command.
  --settings   Open SettingsHub.
  --surfaces   Open the main runtime surfaces used for sanity checks.
  --launcher   Open the launcher in its primary manual QA modes.
  --artifacts  Generate all visual QA matrices and a dashboard index.
  --all        Print the checklist path, journal command, run settings/surfaces/launcher helpers, and generate artifacts.
  -h, --help   Show this help text.
EOF
}

print_checklist() {
  printf '[INFO] Checklist: %s\n' "${checklist_path}"
  printf '\n'
  cat "${checklist_path}"
}

print_journal_cmd() {
  printf '%s\n' "journalctl --user -f | rg 'quickshell|WARN|ERROR'"
}

open_settings() {
  quickshell ipc call SettingsHub open
}

open_surfaces() {
  quickshell ipc call Shell openSurface controlCenter
  quickshell ipc call Shell openSurface notifCenter
  quickshell ipc call Shell openSurface audioMenu
  quickshell ipc call Shell openSurface networkMenu
}

open_launcher() {
  quickshell ipc call Launcher openDrun
  quickshell ipc call Launcher openFiles
  quickshell ipc call Launcher openWeb
}

capture_artifacts() {
  bash "${script_dir}/capture-manual-qa-dashboard.sh"
}

if (( $# == 0 )); then
  usage
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --checklist)
      print_checklist
      ;;
    --journal)
      print_journal_cmd
      ;;
    --settings)
      open_settings
      ;;
    --surfaces)
      open_surfaces
      ;;
    --launcher)
      open_launcher
      ;;
    --artifacts)
      capture_artifacts
      ;;
    --all)
      printf '[INFO] Checklist: %s\n' "${checklist_path}"
      printf '[INFO] Journal: '
      print_journal_cmd
      open_settings
      open_surfaces
      open_launcher
      capture_artifacts
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
  shift
done
