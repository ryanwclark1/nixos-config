#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"
repo_root="${QS_REPO_ROOT:-$(CDPATH= cd -- "${script_dir}/../../../../../../.." >/dev/null 2>&1 && pwd -P)}"

usage() {
  cat <<'EOF'
Usage: health-safe-fix.sh <fix-id>

Supported fix ids:
  normalize-script-dir
EOF
}

require_repo_file() {
  local path="$1"
  if [[ ! -f "${path}" ]]; then
    printf 'Expected repo file missing: %s\n' "${path}" >&2
    exit 1
  fi
}

normalize_script_dir() {
  local old='script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"'
  local new='script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd -P)"'
  local files=(
    "${repo_root}/home/features/desktop/window-managers/shared/panel/quickshell/scripts/check-compositor-guards.sh"
    "${repo_root}/home/features/desktop/window-managers/shared/panel/quickshell/scripts/check-compositor-fixtures.sh"
    "${repo_root}/home/features/desktop/window-managers/shared/panel/quickshell/scripts/compositor-verify.sh"
    "${repo_root}/home/features/desktop/window-managers/shared/panel/quickshell/scripts/compositor-smoke.sh"
  )
  local file

  for file in "${files[@]}"; do
    require_repo_file "${file}"
    if rg -q -F -- "${new}" "${file}"; then
      continue
    fi
    if ! rg -q -F -- "${old}" "${file}"; then
      printf 'Safe fix normalize-script-dir refused unexpected file content: %s\n' "${file}" >&2
      exit 1
    fi
    perl -0pi -e 's/\Q'"${old}"'\E/'"${new}"'/' "${file}"
  done
}

main() {
  local fix_id="${1:-}"
  if [[ -z "${fix_id}" || "${fix_id}" == "-h" || "${fix_id}" == "--help" ]]; then
    usage
    [[ -n "${fix_id}" ]] && exit 0
    exit 2
  fi

  case "${fix_id}" in
    normalize-script-dir)
      normalize_script_dir
      ;;
    *)
      printf 'Unknown fix id: %s\n' "${fix_id}" >&2
      exit 2
      ;;
  esac

  printf 'Applied safe fix: %s\n' "${fix_id}"
}

main "$@"
