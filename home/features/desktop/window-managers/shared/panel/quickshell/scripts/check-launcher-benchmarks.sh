#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
baseline_file="${script_dir}/launcher-benchmark-baselines.json"

if [[ ! -f "${baseline_file}" ]]; then
  printf '%s\n' "Benchmark baseline file is missing: ${baseline_file}" >&2
  exit 1
fi

violations=()

compare_leq() {
  local lhs="$1"
  local rhs="$2"
  awk -v a="$lhs" -v b="$rhs" 'BEGIN { if (a <= b) exit 0; exit 1 }'
}

run_case() {
  local key="$1"
  local script_name="$2"
  local args="$3"

  local baseline_json
  baseline_json="$(node -e 'const fs=require("fs"); const p=process.argv[1]; const k=process.argv[2]; const d=JSON.parse(fs.readFileSync(p,"utf8")); if(!d[k]) process.exit(2); console.log(JSON.stringify(d[k]));' "${baseline_file}" "${key}")" || {
    violations+=("baseline missing for ${key}")
    return
  }

  local max_opt tol
  max_opt="$(node -e 'const d=JSON.parse(process.argv[1]); console.log(Number(d.max_optimized_ms||0));' "${baseline_json}")"
  tol="$(node -e 'const d=JSON.parse(process.argv[1]); console.log(Number(d.tolerance_pct||0));' "${baseline_json}")"
  local max_allowed
  max_allowed="$(awk -v m="${max_opt}" -v t="${tol}" 'BEGIN { printf "%.6f", m * (1 + (t / 100.0)) }')"

  local output
  output="$(node "${script_dir}/${script_name}" ${args} --json)"

  local legacy_median opt_median speedup legacy_checksum opt_checksum
  legacy_median="$(node -e 'const d=JSON.parse(process.argv[1]); console.log(Number(d.legacyMedianMs||0));' "${output}")"
  opt_median="$(node -e 'const d=JSON.parse(process.argv[1]); console.log(Number(d.optimizedMedianMs||0));' "${output}")"
  speedup="$(node -e 'const d=JSON.parse(process.argv[1]); console.log(Number(d.speedup||0));' "${output}")"
  legacy_checksum="$(node -e 'const d=JSON.parse(process.argv[1]); console.log(String(d.legacyChecksum));' "${output}")"
  opt_checksum="$(node -e 'const d=JSON.parse(process.argv[1]); console.log(String(d.optimizedChecksum));' "${output}")"

  if ! compare_leq "${opt_median}" "${max_allowed}"; then
    violations+=("${key} optimized median ${opt_median}ms exceeded allowed ${max_allowed}ms (baseline ${max_opt}ms, tol ${tol}%)")
  fi
  if ! compare_leq "1.0" "${speedup}"; then
    violations+=("${key} speedup dropped below 1.0x (${speedup}x)")
  fi
  if [[ "${legacy_checksum}" != "${opt_checksum}" ]]; then
    violations+=("${key} checksum mismatch legacy=${legacy_checksum} optimized=${opt_checksum}")
  fi

  if [[ "${key}" == "filter" ]]; then
    local legacy_matched opt_matched
    legacy_matched="$(node -e 'const d=JSON.parse(process.argv[1]); console.log(String(d.legacyMatched));' "${output}")"
    opt_matched="$(node -e 'const d=JSON.parse(process.argv[1]); console.log(String(d.optimizedMatched));' "${output}")"
    if [[ "${legacy_matched}" != "${opt_matched}" ]]; then
      violations+=("${key} matched-count mismatch legacy=${legacy_matched} optimized=${opt_matched}")
    fi
  elif [[ "${key}" == "home" ]]; then
    local legacy_count opt_count
    legacy_count="$(node -e 'const d=JSON.parse(process.argv[1]); console.log(String(d.legacyCount));' "${output}")"
    opt_count="$(node -e 'const d=JSON.parse(process.argv[1]); console.log(String(d.optimizedCount));' "${output}")"
    if [[ "${legacy_count}" != "${opt_count}" ]]; then
      violations+=("${key} count mismatch legacy=${legacy_count} optimized=${opt_count}")
    fi
  else
    local legacy_total opt_total
    legacy_total="$(node -e 'const d=JSON.parse(process.argv[1]); console.log(String(d.legacyTotal));' "${output}")"
    opt_total="$(node -e 'const d=JSON.parse(process.argv[1]); console.log(String(d.optimizedTotal));' "${output}")"
    if [[ "${legacy_total}" != "${opt_total}" ]]; then
      violations+=("${key} total mismatch legacy=${legacy_total} optimized=${opt_total}")
    fi
  fi

  printf '%s\n' "${key}: legacy=${legacy_median}ms optimized=${opt_median}ms speedup=${speedup}x (<= ${max_allowed}ms allowed)"
}

run_case "filter" "benchmark-launcher-filter.js" "--items=30000 --runs=40 --seed=1337"
run_case "home" "benchmark-launcher-home.js" "--apps=30000 --history=500 --runs=60 --seed=1337"
run_case "files_shaping" "benchmark-launcher-files-shaping.js" "--lines=120000 --runs=25 --seed=1337"

if (( ${#violations[@]} > 0 )); then
  printf '%s\n' "Launcher benchmark checks failed:" >&2
  printf '  - %s\n' "${violations[@]}" >&2
  exit 1
fi

printf '%s\n' "Launcher benchmark checks passed."
