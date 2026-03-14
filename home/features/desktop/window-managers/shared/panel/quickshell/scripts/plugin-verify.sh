#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf '[INFO] Running plugin conformance checks...\n'
"${script_dir}/check-plugin-conformance.sh"

printf '[INFO] Running plugin doctor smoke checks...\n'
"${script_dir}/check-plugin-doctor-smoke.sh"

printf '[INFO] Running plugin reference local checks...\n'
"${script_dir}/check-plugin-reference-local.sh"

printf '[INFO] Running plugin reference contract checks...\n'
"${script_dir}/check-plugin-reference-contracts.sh"

printf '[INFO] Running plugin reference fixture checks...\n'
"${script_dir}/check-plugin-reference-fixtures.sh"

printf '[INFO] Running plugin reference recovery checks...\n'
"${script_dir}/check-plugin-reference-recovery.sh"

printf '[INFO] Running plugin reference diagnostics checks...\n'
"${script_dir}/check-plugin-reference-diagnostics.sh"

printf '[INFO] Running plugin runtime guard checks...\n'
"${script_dir}/check-plugin-runtime-guards.sh"

printf '[INFO] Running plugin diagnostics contract checks...\n'
"${script_dir}/check-plugin-diagnostics-contracts.sh"

printf '[INFO] Running plugin diagnostics schema sync checks...\n'
"${script_dir}/sync-plugin-diagnostics-schema.sh" --check

printf '[INFO] Running plugin diagnostics schema checks...\n'
"${script_dir}/check-plugin-diagnostics-schema.sh"

printf '[INFO] Plugin verification passed.\n'
