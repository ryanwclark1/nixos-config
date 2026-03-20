#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
skip_switch=0
repo_shell_mode=0
output_dir=""

usage() {
  cat <<'EOF'
Usage: check-settings-qa.sh [--skip-switch] [--repo-shell] [--output-dir PATH]

Run the settings-focused QA stack:
  1. first-open Bar Widgets live validation
  2. settings guardrails
  3. widget picker search regression
  4. bar widget reorder regression

By default this includes the Home Manager deploy path through
check-bar-widgets-first-open.sh. Use --skip-switch if the current repo state is
already deployed, or --repo-shell to run the stack against a repo-shell instance
without deploying Home Manager.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-switch)
      skip_switch=1
      shift
      ;;
    --repo-shell)
      repo_shell_mode=1
      shift
      ;;
    --output-dir)
      output_dir="${2:-}"
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

first_open_args=()
guardrail_args=()

if [[ -n "${output_dir}" ]]; then
  first_open_args+=(--output-dir "${output_dir}")
fi

if (( repo_shell_mode == 1 )); then
  first_open_args+=(--repo-shell)
  guardrail_args+=(--repo-shell)
elif (( skip_switch == 1 )); then
  first_open_args+=(--skip-switch)
fi

bash "${script_dir}/check-bar-widgets-first-open.sh" "${first_open_args[@]}"

# Settings QA already exercises launcher-adjacent settings tabs during the
# smoke step above, and the Bar Widgets first-open gate already performs the
# deep scroll capture that has been flaky in the VM.
bash "${script_dir}/check-settings-guardrails.sh" --skip-responsive --skip-launcher --skip-settings-deep "${guardrail_args[@]}"
bash "${script_dir}/check-widget-picker-search.sh"
bash "${script_dir}/check-bar-widget-reorder.sh"

printf '[PASS] Settings QA completed.\n'
