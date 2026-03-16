#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
skip_switch=0

usage() {
  cat <<'EOF'
Usage: check-settings-qa.sh [--skip-switch]

Run the settings-focused QA stack:
  1. first-open Bar Widgets live validation
  2. settings guardrails
  3. widget picker search regression
  4. bar widget reorder regression

By default this includes the Home Manager deploy path through
check-bar-widgets-first-open.sh. Use --skip-switch if the current repo state is
already deployed.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-switch)
      skip_switch=1
      shift
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

if (( skip_switch == 1 )); then
  bash "${script_dir}/check-bar-widgets-first-open.sh" --skip-switch
else
  bash "${script_dir}/check-bar-widgets-first-open.sh"
fi

bash "${script_dir}/check-settings-guardrails.sh"
bash "${script_dir}/check-widget-picker-search.sh"
bash "${script_dir}/check-bar-widget-reorder.sh"

printf '[PASS] Settings QA completed.\n'
