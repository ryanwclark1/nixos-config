#!/usr/bin/env bash
set -euo pipefail

# Helper to promote a QA output directory to be the new "Gold Standard" baselines.

usage() {
  cat <<EOF
Usage: promote-baselines.sh <QA_OUTPUT_DIR> [TARGET_BASELINE_DIR]

Promotes screenshots from a QA pass to be the new baselines.
If TARGET_BASELINE_DIR is omitted, it will create a 'baselines' folder inside the QA_OUTPUT_DIR.

Example:
  ./scripts/promote-baselines.sh /tmp/quickshell-qa-20260316-180000
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

src_dir="$1"
target_dir="${2:-$1/baselines}"

if [[ ! -d "${src_dir}" ]]; then
  printf 'Source directory does not exist: %s\n' "${src_dir}" >&2
  exit 1
fi

mkdir -p "${target_dir}"

printf '[INFO] Promoting captures from %s to %s...\n' "${src_dir}" "${target_dir}"

# Find all PNGs in the source (excluding any existing baselines)
find "${src_dir}" -name "*.png" -not -path "*/baselines/*" | while read -r img; do
  # Calculate relative path from src_dir
  rel_path="${img#${src_dir}/}"
  dest_path="${target_dir}/${rel_path}"
  
  mkdir -p "$(dirname "${dest_path}")"
  cp "${img}" "${dest_path}"
  printf '  + %s\n' "${rel_path}"
done

printf '[SUCCESS] Baselines promoted. Re-run your QA pass to verify comparison mode.\n'
