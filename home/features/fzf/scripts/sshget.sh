#!/usr/bin/env bash

declare -r esc=$'\033'
declare -r c_reset="${esc}[0m"
declare -r c_red="${esc}[31m"

declare -r fifo='/tmp/sshget.fifo'
declare -A domains=()
declare -A paths=()
declare -a files=()

err() {
  printf "${c_red}%s${c_reset}\n" "$*" >&2
}

die() {
  exit 1
}

usage() {
  LESS=-FEXR less <<'HELP'
sshget <user@host1:/path/to/search ...>
HELP
}

has() {
  local verbose=0
  if [[ $1 = '-v' ]]; then
    verbose=1
    shift
  fi
  for c; do c="${c%% *}"
    if ! command -v "$c" &> /dev/null; then
      (( verbose > 0 )) && err "$c not found"
      return 1
    fi
  done
}

has -v fzf rsync || die

cleanup() {
  [[ -e "$fifo" ]] && rm -f "$fifo" 2>/dev/null || true
  # Kill any background jobs
  jobs -p | xargs -r kill 2>/dev/null || true
}
trap cleanup EXIT SIGHUP SIGINT SIGTERM

# Remove existing FIFO if it exists
[[ -e "$fifo" ]] && rm -f "$fifo"

# Create new FIFO
if ! mkfifo "$fifo" 2>/dev/null; then
  err "Failed to create FIFO: $fifo"
  die
fi

if (( $# < 1 )); then
  usage
  die
fi

for a; do
  host="${a%:*}"
  path="${a##*:}"
  domains+=( ["$a"]="$host" )
  paths+=( ["$a"]="$path" )
done

for s in "${!domains[@]}"; do
  (
    if ssh "${domains[$s]}" "find \"${paths[$s]}\" -type f" 2>/dev/null | sed -r "s|^|${domains[$s]}:|"; then
      : # Success
    else
      err "Failed to list files on ${domains[$s]}:${paths[$s]}" >&2
    fi
  ) >> "$fifo" &
done

# Wait for all background jobs to finish before reading from FIFO
wait 2>/dev/null || true

mapfile -t files < <(fzf -e --inline-info +s --multi --cycle --bind='Ctrl-A:toggle-all,`:jump' < "$fifo" || true)

if (( ${#files[@]} > 0 )); then
  if rsync --protect-args -auvzP -e ssh "${files[@]}" . 2>&1; then
    : # Success - cleanup will be handled by trap
  else
    err "Some files failed to transfer"
    exit 1
  fi
fi
