#!/usr/bin/env bash

set -Eeuo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

"${script_dir}"/harness.sh --test "${script_dir}"/default_options.sh --expected "${script_dir}"/default_options_expected.txt "$@"
"${script_dir}"/harness.sh --test "${script_dir}"/window_status_styling.sh --expected "${script_dir}"/window_status_styling_expected.txt "$@"

"${script_dir}"/harness.sh --test "${script_dir}"/application_module.sh --expected "${script_dir}"/application_module_expected.txt "$@"
"${script_dir}"/harness.sh --test "${script_dir}"/battery_module.sh --expected "${script_dir}"/battery_module_expected.txt "$@"
"${script_dir}"/harness.sh --test "${script_dir}"/cpu_module.sh --expected "${script_dir}"/cpu_module_expected.txt "$@"
"${script_dir}"/harness.sh --test "${script_dir}"/pane_styling.sh --expected "${script_dir}"/pane_styling_expected.txt "$@"
