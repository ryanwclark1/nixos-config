#!/usr/bin/env bash

set -o pipefail

# -------- Catppuccin Frappé Colors --------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly RESET='\033[0m'

declare processes=4
declare quiet
declare force
declare -a dirs
declare -a ignore_dir
declare -a ignore_dirs
declare -a errs
declare -a success_repos

usage() {
  LESS=-FEXR less <<'HELP'
gitup [OPTIONS] [dirs]

search for git repos and update them

if unspecified, dir defaults to $HOME

  -i [dir]       comma separated list of directory paths to not search
  -p [number]    how many processes to run `git pull` in parallel
  -q             quiet level, may be stacked
                 first level suppresses output from `git pull`
                 second level suppresses job info
  -F             don't run interactively, `git pull` all dirs
                 use with caution, make sure you know which dirs will be matched
                 works best if gitup is provided a list of dirs known to have git repos
  -h             print this help
HELP
}

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

if ! has -v fzf git; then
  err "fzf and git are required"
  err "Install: nix-env -iA nixos.fzf nixos.git"
  exit 1
fi

while getopts ':hqp:i:F' x; do o="$OPTARG"
  case "$x" in
    h) usage; exit; ;;
    p) processes="$o" ;;
    q) (( ++quiet )) ;;
    i) IFS=',' read -ra ignore_dir <<< "$o" ;;
    F) (( ++force )) ;;
  esac
done
shift $(( OPTIND - 1 ))

while :; do
  if [[ -d "$1" ]]; then
    dirs+=( "$1" )
  fi
  shift || break
done

for o in "${ignore_dir[@]}"; do
  ignore_dirs+=( -path "*/$o" -o  )
done

(( ${#dirs[@]} > 0 )) || dirs=("$HOME")

# Build find command - handle both GNU and BSD find
# Add common exclusions to prevent hanging on large directories
common_excludes=(
  -path '*/node_modules' -o
  -path '*/.cache' -o
  -path '*/.npm' -o
  -path '*/.local/share/Trash' -o
  -path '*/Library/Caches' -o
  -path '*/__pycache__' -o
  -path '*/.venv' -o
)

if find --version &>/dev/null; then
  # GNU find with -printf
  mapfile -t repos < <(
    find "${dirs[@]}" \
      -maxdepth 10 \
      \( "${ignore_dirs[@]}" \
        "${common_excludes[@]}" \
        -fstype 'devfs' \
        -o -fstype 'devtmpfs' \
        -o -fstype 'proc' \
        -o -fstype 'sysfs' \
        -o -fstype 'tmpfs' \
      \) -prune -o -name '.git' -type d -printf '%h\n' 2>/dev/null |
      sort -u |
      fzf --multi --cycle --inline-info +s -e ${force:+-f /}
  )
else
  # BSD find fallback
  mapfile -t repos < <(
    find "${dirs[@]}" \
      -maxdepth 10 \
      \( "${ignore_dirs[@]}" \
        "${common_excludes[@]}" \
        -fstype 'devfs' \
        -o -fstype 'devtmpfs' \
        -o -fstype 'proc' \
        -o -fstype 'sysfs' \
        -o -fstype 'tmpfs' \
      \) -prune -o -name '.git' -type d -print 2>/dev/null |
      sed 's|/\.git$||' |
      sort -u |
      fzf --multi --cycle --inline-info +s -e ${force:+-f /}
  )
fi

(( ${#repos[@]} > 0 )) || exit

update() {
  local name dir output exit_code
  dir="$1"
  name="${dir##*/}"

  # Validate it's actually a git repo
  if ! git -C "$dir" rev-parse --git-dir &>/dev/null; then
    errs+=( "$name (not a git repo)" )
    (( quiet > 1 )) || err ":: $name is not a valid git repository"
    return 1
  fi

  (( quiet > 1 )) || info "Updating $name..."

  # Capture output for better error reporting
  if output=$(git -C "$dir" pull ${quiet:+-q} 2>&1); then
    exit_code=$?
    # Check if there were actual changes
    if echo "$output" | grep -qE "(Already up to date|Fast-forward|Updating)"; then
      success_repos+=( "$name" )
      (( quiet > 1 )) || success "Updated $name"
    else
      success_repos+=( "$name" )
      (( quiet > 1 )) || success "Updated $name"
    fi
    return $exit_code
  else
    exit_code=$?
    errs+=( "$name" )
    (( quiet > 1 )) || err "Failed to update $name"
    if (( quiet == 0 )); then
      echo "$output" | head -3 | while IFS= read -r line; do
        [[ -n "$line" ]] && warn "  $line"
      done
    fi
    return $exit_code
  fi
}

# Update repos in parallel with better progress tracking
count=0
total=${#repos[@]}
(( quiet > 1 )) || info "Updating $total repository/repositories with $processes parallel processes..."

for d in "${repos[@]}"; do
  (( count++ >= processes )) && wait -n
  update "$d" &
done

# Wait for all background jobs
wait

# Summary
local success_count=${#success_repos[@]}
local error_count=${#errs[@]}

if (( error_count > 0 )); then
  echo
  err "The following repositories failed to update:"
  for repo in "${errs[@]}"; do
    err "  - $repo"
  done
fi

if (( success_count > 0 )); then
  success "Successfully updated $success_count repository/repositories"
fi

if (( error_count == 0 && success_count > 0 )); then
  success "All repositories updated successfully!"
fi
