#!/usr/bin/env bash

set -euo pipefail

# -------- Catppuccin Frappé Colors --------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly RESET='\033[0m'

declare dryrun verbose

err() {
  printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2
}

info() {
  printf "${BLUE}[INFO]${RESET} %s\n" "$*"
}

warn() {
  printf "${YELLOW}[WARNING]${RESET} %s\n" "$*"
}

success() {
  printf "${GREEN}[SUCCESS]${RESET} %s\n" "$*"
}

die() {
  [[ $# -gt 0 ]] && err "$*"
  exit 1
}

has() {
  local verbose=false
  if [[ ${1:-} == '-v' ]]; then
    verbose=true
    shift
  fi
  for cmd in "$@"; do
    if ! command -v "${cmd%% *}" &>/dev/null; then
      [[ "$verbose" == true ]] && err "$cmd not found"
      return 1
    fi
  done
  return 0
}

if ! has -v fzf; then
  err "fzf is required but not found"
  err "Install fzf: nix-env -iA nixos.fzf"
  exit 1
fi

fzf() {
  command fzf --cycle "$@"
}

pick_files() {
  local f
  find . -maxdepth 1 -mindepth 1 2>/dev/null |
    sort -h |
    sed 's|^\./||' |
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      if [[ -d "$f" ]]; then
        printf '%s/\n' "$f"
      elif [[ -L "$f" ]]; then
        printf '%s@\n' "$f"
      else
        printf '%s\n' "$f"
      fi
    done |
    fzf --multi --header='move these files' || return 1
}

pick_destination() {
  local cwd browse_dir browse_info query dirs
  cwd=$(pwd) || die "Failed to get current directory"

  # Use XDG cache directory for history
  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/fzmv"
  mkdir -p "$cache_dir" || die "Failed to create cache directory"
  local history_file="$cache_dir/history"

  while [[ "$browse_dir" != "$cwd" ]]; do
    mapfile -t browse_info < <(
      { echo '..'; find . -maxdepth 1 -mindepth 1 -type d 2>/dev/null; } |
        sed 's|^./||' |
        sort -h |
        fzf --print-query \
        --history="$history_file" \
        --header="${errors:-move files here}" || return 1
    )
    [[ ${#browse_info[@]} -eq 0 ]] && return 1

    query=${browse_info[0]:-}
    browse_dir=${browse_info[1]:-}
    files=( "${browse_info[@]:2}" )
    [[ -d "$query" ]] && browse_dir="$query"
    [[ ! -d "$browse_dir" ]] && return 1
    if [[ "$browse_dir" == '.' && $(realpath "$browse_dir" 2>/dev/null) != "$cwd" ]]; then
      realpath "$browse_dir" 2>/dev/null || echo "$browse_dir"
      break
    else
      cd "$browse_dir" || die "Failed to change directory to: $browse_dir"
      continue
    fi
  done
}

while (( $# > 0 )); do
  case $1 in
    -t|--test) dryrun=true ;;
    -v|--verbose) verbose=1 ;;
  esac
  shift
done

mapfile -t files < <(pick_files)
if (( ${#files[@]} == 0 )); then
  info "No files selected"
  exit 0
fi

destination=$(pick_destination) || {
  err "No destination selected"
  exit 1
}

if [[ -z "$destination" ]]; then
  err "No destination selected"
  exit 1
fi

# Validate destination exists and is writable
if [[ ! -d "$destination" ]]; then
  err "Destination is not a directory: $destination"
  exit 1
fi

if [[ ! -w "$destination" ]]; then
  err "Destination is not writable: $destination"
  warn "You may need to run with sudo or change permissions"
  exit 1
fi

# Validate all source files exist
local missing_files=()
for file in "${files[@]}"; do
  if [[ ! -e "$file" ]]; then
    missing_files+=( "$file" )
  fi
done

if (( ${#missing_files[@]} > 0 )); then
  err "Some selected files do not exist:"
  for file in "${missing_files[@]}"; do
    err "  - $file"
  done
  exit 1
fi

# Show what will be moved
if [[ -n "${dryrun:-}" ]]; then
  info "DRY RUN - Would move the following files:"
  for file in "${files[@]}"; do
    info "  $file -> $destination/"
  done
else
  info "Moving ${#files[@]} file(s) to $destination"
fi

# Perform the move
if ${dryrun:+echo} mv ${verbose:+-v} -t "$destination" "${files[@]}" 2>&1; then
  if [[ -z "${dryrun:-}" ]]; then
    success "Successfully moved ${#files[@]} file(s) to $destination"
  fi
else
  local exit_code=$?
  err "Failed to move files"
  warn "Some files may have been moved. Check destination: $destination"
  exit $exit_code
fi
