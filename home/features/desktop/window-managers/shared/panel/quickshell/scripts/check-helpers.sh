#!/usr/bin/env bash
# Shared helpers for contract-check scripts.
# Source this file after setting: script_dir, config_dir, violations=()

# require_literal FILE NEEDLE LABEL [ALT_FILE]
# Fails if NEEDLE is not found as a literal string in FILE (or ALT_FILE).
require_literal() {
  local file="$1"
  local needle="$2"
  local label="$3"
  local alt_file="${4:-}"
  if ! rg -n -F -- "$needle" "$file" >/dev/null 2>&1; then
    if [[ -n "${alt_file}" ]] && rg -n -F -- "$needle" "${alt_file}" >/dev/null 2>&1; then
        return 0
    fi
    violations+=("${label} missing in ${file}${alt_file:+ or ${alt_file}}")
  fi
}

# require_pattern FILE PATTERN LABEL [EXTRA_RG_ARGS...]
# Fails if regex PATTERN is not found in FILE.
require_pattern() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  shift 3
  if ! rg -n "$@" -- "$pattern" "$file" >/dev/null 2>&1; then
    violations+=("${label} missing in ${file}")
  fi
}

# forbid_literal FILE NEEDLE LABEL
# Fails if NEEDLE IS found in FILE.
forbid_literal() {
  local file="$1"
  local needle="$2"
  local label="$3"
  if rg -n -F -- "$needle" "$file" >/dev/null 2>&1; then
    violations+=("${label} — found in ${file}")
  fi
}

# report_violations TITLE
# Prints violations and exits 1 if any, otherwise prints success.
report_violations() {
  local title="${1:-Check}"
  if (( ${#violations[@]} > 0 )); then
    printf '%s\n' "${title} failed:" >&2
    printf '  - %s\n' "${violations[@]}" >&2
    exit 1
  fi
  printf '%s\n' "${title} passed."
}
