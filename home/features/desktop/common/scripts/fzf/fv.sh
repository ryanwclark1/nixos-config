#!/usr/bin/env bash

set -euo pipefail

# -------- Catppuccin Frappé Colors --------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly RESET='\033[0m'

# -------- Helper Functions --------
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

usage() {
  cat << 'HELP'
fv [OPTIONS] [SEARCH]
Fuzzy file filtering and command executing

Options:
  -a          Search all directories and hidden files
  -c CMD      Command to execute [defaults to vim]
  -d          Run in background (detached)
  -h          Show this help
  -l          Additional search program options
  -o          Run continuously
  -s          Use a smaller window

Environment:
  FV_CMD       Override the editor
  FV_SEARCH    Override the search tool (rg/ag/ack/grep)
HELP
}

select_from() {
  local o cmd='command -v' c cmd_path
  local OPTIND=1        # <<< reset OPTIND for getopts in this function
  while getopts 'c:' o; do
    case "$o" in
      c) cmd="$OPTARG" ;;
    esac
  done
  shift "$((OPTIND-1))"
  for c; do
    cmd_path=$($cmd "${c%% *}" 2>/dev/null)
    if [[ -n "$cmd_path" ]] && [[ -x "$cmd_path" ]]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

get_preview_command() {
  # Prefer fzf-preview if available, then bat, highlight, or cat
  if command -v fzf-preview &>/dev/null; then
    echo 'fzf-preview'
  else
    select_from 'bat --color=always --style=header' \
                'highlight -q --force -O ansi' \
                'cat'
  fi
}

# -------- Vars --------
declare cmd='' cmdopts=()
declare search_cmd='' search_str=''
declare search_opts=()
declare allfiles='' loop='' small='' dtach=''

# -------- Arg Parse --------
while getopts 'ac:dhlos' opt; do
  case "$opt" in
    a) allfiles=1 ;;
    c) cmd="$OPTARG" ;;
    d) dtach=1 ;;
    h) usage; exit 0 ;;
    l) search_opts+=( '-l' ) ;;
    o) loop=1 ;;
    s) small=1 ;;
  esac
done
shift "$((OPTIND-1))"

# -------- Prechecks --------
if ! has -v fzf; then
  err "fzf is required but not found"
  err "Install fzf: nix-env -iA nixos.fzf"
  exit 1
fi

# Editor
if [[ -v FV_CMD ]]; then
  cmd="$FV_CMD"
elif [[ -z "$cmd" ]]; then
  cmd=$(select_from 'nvim' 'vim' 'vi')
fi
[[ -z "$cmd" ]] && die "No suitable editor found."

# Search Tool
if [[ -v FV_SEARCH && -n "$FV_SEARCH" ]]; then
  search_cmd="$FV_SEARCH"
  # Normalize ripgrep to rg for option handling
  [[ "$search_cmd" == "ripgrep" ]] && search_cmd="rg"
  # Validate the specified tool exists
  if ! command -v "$search_cmd" &>/dev/null; then
    err "Specified search tool not found: $FV_SEARCH"
    die
  fi
else
  # Check for ripgrep (rg) first, then ag, ack, grep
  # Also check for 'ripgrep' in case rg symlink doesn't exist
  # Use explicit PATH check as fallback for Nix environments
  if command -v rg &>/dev/null && [[ -x "$(command -v rg)" ]]; then
    search_cmd="rg"
  elif command -v ripgrep &>/dev/null && [[ -x "$(command -v ripgrep)" ]]; then
    search_cmd="rg"  # Normalize to rg
  else
    search_cmd=$(select_from 'ag' 'ack' 'grep')
  fi
fi
if [[ -z "$search_cmd" ]]; then
  err "No search tool found (install rg/ag/ack/grep)"
  err "Recommended: nix-env -iA nixos.ripgrep"
  exit 1
fi

if [[ "$search_cmd" == "grep" ]]; then
  warn "grep is slow. Consider installing rg or ag for better performance."
  sleep 0.5
fi

# Input
if [[ -n "$1" ]]; then
  if [[ -e "$1" ]]; then
    search_opts+=( "$1" )
  else
    search_str="$1"
  fi
  shift
fi

# -------- Search Options --------
case "$search_cmd" in
  'rg')
    search_opts+=( '--color=always' )
    if [[ -z "$search_str" ]]; then
      # When no search string, list files instead of searching
      search_opts+=( '--files' )
      [[ -n "$allfiles" ]] && search_opts+=( '--hidden' '--no-ignore' )
      [[ -z "$allfiles" ]] && search_opts+=( '--glob=!{bower_components,node_modules,jspm_packages,.cvs,.git,.hg,.svn}' )
    else
      # When searching, use -l to list matching files
      search_opts+=( '-l' )
      [[ -n "$allfiles" ]] && search_opts+=( '--hidden' '--no-ignore' )
      [[ -z "$allfiles" ]] && search_opts+=( '--glob=!{bower_components,node_modules,jspm_packages,.cvs,.git,.hg,.svn}' )
    fi
    ;;
  'ag')
    search_opts+=( '--color' )
    [[ -n "$allfiles" ]] && search_opts+=( '-u' '--hidden' )
    [[ -z "$search_str" ]] && search_opts+=( '-l' )
    ;;
  'ack')
    if [[ -z "$search_str" ]]; then
      [[ -z "$allfiles" ]] && search_opts+=( '-f' ) || search_opts+=( '-g' '^[^\.]' )
    else
      search_opts+=( '-l' )
    fi
    ;;
  'grep')
    search_opts+=( '-r' '-I' )
    if [[ -z "$allfiles" ]]; then
      if [[ -r ~/.ignore ]]; then
        while read -r line; do
          [[ -n "$line" ]] && search_opts+=( "--exclude-dir=$line" )
        done < ~/.ignore
      else
        search_opts+=( '--exclude-dir={bower_components,node_modules,jspm_packages,.cvs,.git,.hg,.svn}' )
      fi
    fi
    [[ -z "$search_str" ]] && search_opts+=( -F '' ) || search_opts+=( -P )
    ;;
esac

[[ -n "$search_str" ]] && search_opts+=( "$search_str" )

# -------- Main Execution --------
main() {
  local choices preview preview_cmd
  preview=$(get_preview_command)

  # Build preview command
  if [[ "$preview" == "fzf-preview" ]]; then
    preview_cmd='fzf-preview {}'
  else
    preview_cmd="[[ \$(file -ib {} 2>/dev/null) == text/* ]] && $preview {} 2>/dev/null || echo 'Binary file or preview unavailable'"
  fi

  # Limit results to prevent overwhelming fzf
  choices=$($search_cmd "${search_opts[@]}" 2>/dev/null | head -10000 |
    fzf --ansi --multi \
        --preview="$preview_cmd" \
        --preview-window=right:60%,border-left \
        --height=80% \
        --border=rounded) || return 1

  # Handle results - ag outputs file:line:match format
  if [[ -n "$search_str" && "$search_cmd" == 'ag' ]]; then
    choices=$(echo "$choices" | cut -d: -f1)
  fi

  # Convert to array, handling empty results
  mapfile -t choices <<< "$choices"
  [[ ${#choices[@]} -eq 0 ]] && return 1

  # Filter out empty entries
  local -a valid_choices=()
  for choice in "${choices[@]}"; do
    [[ -n "$choice" ]] && valid_choices+=("$choice")
  done

  [[ ${#valid_choices[@]} -eq 0 ]] && return 1

  if [[ -n "$dtach" ]]; then
    ( "$cmd" "${cmdopts[@]}" "${valid_choices[@]}" &> /dev/null & )
  else
    "$cmd" "${cmdopts[@]}" "${valid_choices[@]}"
  fi
}

# -------- Loop Mode --------
if [[ -n "$loop" ]]; then
  while main; do :; done
else
  main
fi
