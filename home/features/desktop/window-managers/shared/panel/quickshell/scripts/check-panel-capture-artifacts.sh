#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

output_dir=""
settings_preset="portrait"
surface_crop="surface"
run_launcher=1
run_settings=1
run_surfaces=1
expect_settings_deep=0
pass_count=0
fail_count=0

launcher_required_files=(
  "drun-home.png"
  "drun-query.png"
  "files-empty.png"
  "system-home.png"
)

settings_tabs=(
  "launcher"
  "launcher-search"
  "launcher-web"
  "launcher-modes"
  "launcher-runtime"
  "ai"
  "wallpaper"
  "bar-widgets"
  "bars"
  "system"
  "plugins"
  "theme"
  "hotkeys"
  "time-weather"
)

surface_ids=(
  "networkMenu"
  "vpnMenu"
  "audioMenu"
  "weatherMenu"
  "dateTimeMenu"
  "notifCenter"
  "controlCenter"
  "systemMonitor"
)

usage() {
  cat <<'EOF'
Usage: check-panel-capture-artifacts.sh --dir DIR [--settings-preset portrait|laptop|wide] [--surface-crop surface|monitor|usable] [--skip-launcher] [--skip-settings] [--skip-surfaces] [--expect-settings-deep]

Validate that a panel QA capture bundle contains the expected review artifacts.
This checks file presence, non-empty PNG captures, basic image dimensions, and galleries.
EOF
}

pass() {
  printf '[PASS] %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 2
  fi
}

validate_png() {
  local png_path="$1"
  local min_width="${2:-200}"
  local min_height="${3:-200}"

  node - "${png_path}" "${min_width}" "${min_height}" <<'NODE'
const fs = require("fs");

const filePath = process.argv[2];
const minWidth = Number(process.argv[3]);
const minHeight = Number(process.argv[4]);
const buf = fs.readFileSync(filePath);

if (buf.length < 24) {
  console.error(`PNG too small: ${filePath}`);
  process.exit(1);
}

const signature = "89504e470d0a1a0a";
if (buf.subarray(0, 8).toString("hex") !== signature) {
  console.error(`Not a PNG: ${filePath}`);
  process.exit(1);
}

const width = buf.readUInt32BE(16);
const height = buf.readUInt32BE(20);
if (width < minWidth || height < minHeight) {
  console.error(`Unexpected dimensions for ${filePath}: ${width}x${height}`);
  process.exit(1);
}
NODE
}

validate_gallery_dir() {
  local dir_path="$1"
  [[ -f "${dir_path}/index.html" ]]
}

validate_launcher_dir() {
  local dir_path="$1"
  local preset="$2"
  local file_name=""

  if [[ ! -d "${dir_path}" ]]; then
    fail "Missing launcher capture directory: ${dir_path}"
    return
  fi

  if validate_gallery_dir "${dir_path}"; then
    pass "Launcher gallery present for ${preset}"
  else
    fail "Launcher gallery missing for ${preset}"
  fi

  for file_name in "${launcher_required_files[@]}"; do
    if [[ -f "${dir_path}/${file_name}" ]] && validate_png "${dir_path}/${file_name}" 200 200; then
      pass "Launcher artifact ${preset}/${file_name}"
    else
      fail "Launcher artifact missing or invalid: ${dir_path}/${file_name}"
    fi
  done
}

validate_settings_dir() {
  local dir_path="$1"
  local deep_suffix="${2:-}"
  local tab_id=""
  local png_path=""

  if [[ ! -d "${dir_path}" ]]; then
    fail "Missing settings capture directory: ${dir_path}"
    return
  fi

  if validate_gallery_dir "${dir_path}"; then
    pass "Settings gallery present${deep_suffix}"
  else
    fail "Settings gallery missing${deep_suffix}"
  fi

  for tab_id in "${settings_tabs[@]}"; do
    png_path="${dir_path}/${settings_preset}-${tab_id}.png"
    if [[ -f "${png_path}" ]] && validate_png "${png_path}" 200 200; then
      pass "Settings artifact ${tab_id}${deep_suffix}"
    else
      fail "Settings artifact missing or invalid: ${png_path}"
    fi
  done
}

validate_surfaces_dir() {
  local dir_path="$1"
  local surface_id=""
  local png_path=""

  if [[ ! -d "${dir_path}" ]]; then
    fail "Missing surface capture directory: ${dir_path}"
    return
  fi

  if validate_gallery_dir "${dir_path}"; then
    pass "Surface gallery present"
  else
    fail "Surface gallery missing"
  fi

  for surface_id in "${surface_ids[@]}"; do
    png_path="${dir_path}/${surface_id}-${surface_crop}.png"
    if [[ -f "${png_path}" ]] && validate_png "${png_path}" 200 200; then
      pass "Surface artifact ${surface_id}"
    else
      fail "Surface artifact missing or invalid: ${png_path}"
    fi
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      output_dir="${2:-}"
      shift 2
      ;;
    --settings-preset)
      settings_preset="${2:-}"
      shift 2
      ;;
    --surface-crop)
      surface_crop="${2:-}"
      shift 2
      ;;
    --skip-launcher)
      run_launcher=0
      shift
      ;;
    --skip-settings)
      run_settings=0
      shift
      ;;
    --skip-surfaces)
      run_surfaces=0
      shift
      ;;
    --expect-settings-deep)
      expect_settings_deep=1
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

if [[ -z "${output_dir}" ]]; then
  printf '--dir is required.\n' >&2
  usage >&2
  exit 2
fi

require_cmd node

if [[ -f "${output_dir}/index.html" ]]; then
  pass "Top-level panel QA gallery present"
else
  fail "Top-level panel QA gallery missing"
fi

if (( run_launcher == 1 )); then
  validate_launcher_dir "${output_dir}/launcher-portrait" "portrait"
  validate_launcher_dir "${output_dir}/launcher-laptop" "laptop"
  validate_launcher_dir "${output_dir}/launcher-wide" "wide"
fi

if (( run_settings == 1 )); then
  validate_settings_dir "${output_dir}/settings-${settings_preset}"
  if (( expect_settings_deep == 1 )); then
    validate_settings_dir "${output_dir}/settings-${settings_preset}-deep" " (deep)"
  fi
fi

if (( run_surfaces == 1 )); then
  validate_surfaces_dir "${output_dir}/surfaces-${surface_crop}"
fi

printf '[INFO] Capture artifact validation summary: %d pass, %d fail\n' "${pass_count}" "${fail_count}"
(( fail_count == 0 ))
