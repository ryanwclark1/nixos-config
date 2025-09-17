#!/usr/bin/env bash

usage() {
  LESS=-FEXR less <<'HELP'
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

# -------- Colors --------
declare -A colors
colors[red]=$(tput setaf 1)$(tput bold)
colors[green]=$(tput setaf 2)$(tput bold)
colors[blue]=$(tput setaf 4)$(tput bold)
colors[reset]=$(tput sgr0)

color() {
  local c="$1"
  shift
  printf '%s%s%s\n' "${colors[$c]}" "$*" "${colors[reset]}"
}

err() {
  color red "$@" >&2
}

die() {
  [[ -n "$1" ]] && err "$1"
  exit 1
}

# -------- Helpers --------
has() {
  local o verbose=0 c
  while getopts 'v' o; do
    case "$o" in v) verbose=1 ;; esac
  done
  shift "$((OPTIND-1))"
  for c; do
    if ! command -v "${c%% *}" &> /dev/null; then
      (( verbose > 0 )) && err "$c not found"
      return 1
    fi
  done
}

select_from() {
  local o cmd='command -v' c
  while getopts 'c:' o; do
    case "$o" in
      c) cmd="$OPTARG" ;;
    esac
  done
  shift "$((OPTIND-1))"
  for c; do
    if $cmd "${c%% *}" &> /dev/null; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

get_preview_command() {
  select_from 'bat --color=always --style=header' \
              'highlight -q --force -O ansi' \
              'cat'
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
has -v 'fzf' || die "fzf is required but not found"

# Editor
if [[ -v FV_CMD ]]; then
  cmd="$FV_CMD"
elif [[ -z "$cmd" ]]; then
  cmd=$(select_from 'nvim' 'vim' 'vi')
fi
[[ -z "$cmd" ]] && die "No suitable editor found."

# Search Tool
if [[ -v FV_SEARCH ]]; then
  search_cmd="$FV_SEARCH"
else
  search_cmd=$(select_from 'rg' 'ag' 'ack' 'grep')
fi
[[ -z "$search_cmd" ]] && die "No search tool found (install rg/ag/ack/grep)"
[[ "$search_cmd" == "grep" ]] && err "Warning: grep is slow. Consider installing rg or ag." && sleep .75

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
    [[ -n "$allfiles" ]] && search_opts+=( '--hidden' '--no-ignore' )
    [[ -z "$search_str" ]] && search_opts+=( '-l' )
    [[ -z "$allfiles" ]] && search_opts+=( '--glob=!{bower_components,node_modules,jspm_packages,.cvs,.git,.hg,.svn}' )
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
          search_opts+=( "--exclude-dir=$line" )
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
  local choices preview
  preview=$(get_preview_command)

  choices=$($search_cmd "${search_opts[@]}" 2> /dev/null |
    fzf --ansi --multi --preview="[[ \$(file -ib {}) == text/* ]] && $preview {} || echo 'Binary file'" --preview-window=right:60%) || return 1

  # Handle results
  [[ "$search_str" != '' && "$search_cmd" == 'ag' ]] && choices=$(cut -d: -f1 <<< "$choices")

  mapfile -t choices <<< "$choices"
  [[ ${#choices[@]} -eq 0 ]] && return 1

  if [[ $dtach ]]; then
    ($cmd "${cmdopts[@]}" "${choices[@]}" &> /dev/null &)
  else
    $cmd "${cmdopts[@]}" "${choices[@]}"
  fi
}

# -------- Loop Mode --------
if [[ -n "$loop" ]]; then
  while main; do true; done
else
  main
fi
