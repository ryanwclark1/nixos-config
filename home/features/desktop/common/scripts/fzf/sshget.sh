#!/usr/bin/env bash

set -o pipefail

# -------- Catppuccin Frappé Colors --------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly RESET='\033[0m'

declare -r fifo='/tmp/sshget.fifo'
declare -A domains=()
declare -A paths=()
declare -a files=()

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

usage() {
  cat << 'HELP'
sshget <user@host1:/path/to/search ...>

Transfer files from remote hosts via SSH using fzf for selection.

Examples:
  sshget user@server:/home/user/documents
  sshget user1@host1:/path1 user2@host2:/path2
HELP
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

if ! has -v fzf rsync ssh; then
  err "fzf, rsync, and ssh are required"
  err "Install: nix-env -iA nixos.fzf nixos.rsync nixos.openssh"
  exit 1
fi

cleanup() {
  [[ -e "$fifo" ]] && rm -f "$fifo" 2>/dev/null || true
  # Kill any background jobs
  local pids
  pids=$(jobs -p 2>/dev/null || true)
  if [[ -n "$pids" ]]; then
    echo "$pids" | xargs -r kill 2>/dev/null || true
  fi
}
trap cleanup EXIT SIGHUP SIGINT SIGTERM

# Remove existing FIFO if it exists
[[ -e "$fifo" ]] && rm -f "$fifo"

# Create new FIFO
if ! mkfifo "$fifo" 2>/dev/null; then
  err "Failed to create FIFO: $fifo"
  err "Another instance may be running or /tmp is not writable"
  exit 1
fi

if (( $# < 1 )); then
  usage
  exit 1
fi

# Parse arguments
for a; do
  if [[ "$a" != *:* ]]; then
    err "Invalid format: $a"
    err "Expected format: user@host:/path"
    exit 1
  fi
  host="${a%:*}"
  path="${a##*:}"

  if [[ -z "$host" ]] || [[ -z "$path" ]]; then
    err "Invalid format: $a (missing host or path)"
    exit 1
  fi

  domains["$a"]="$host"
  paths["$a"]="$path"
done

info "Scanning for files on ${#domains[@]} remote host(s)..."

# Test SSH connections first
for s in "${!domains[@]}"; do
  if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "${domains[$s]}" "echo" &>/dev/null; then
    warn "Cannot connect to ${domains[$s]} (will still attempt, may require password)"
  fi
done

# List files from all hosts in parallel
for s in "${!domains[@]}"; do
  (
    if ssh "${domains[$s]}" "find \"${paths[$s]}\" -type f 2>/dev/null" 2>/dev/null | sed -r "s|^|${domains[$s]}:|"; then
      : # Success
    else
      err "Failed to list files on ${domains[$s]}:${paths[$s]}" >&2
      err "Check SSH connection and path permissions" >&2
    fi
  ) >> "$fifo" &
done

# Wait for all background jobs to finish before reading from FIFO
wait 2>/dev/null || true

# Check if we got any results
if [[ ! -s "$fifo" ]]; then
  err "No files found on any remote host"
  err "Check paths and SSH connectivity"
  exit 1
fi

info "Select files to transfer (use Tab to select multiple, Enter to confirm)"

mapfile -t files < <(fzf -e --inline-info +s --multi --cycle \
  --bind='Ctrl-A:toggle-all,`:jump' \
  --header="Select files to transfer from remote hosts" \
  < "$fifo" || true)

if (( ${#files[@]} == 0 )); then
  info "No files selected"
  exit 0
fi

info "Transferring ${#files[@]} file(s)..."

# Transfer files with progress indication
if rsync --protect-args -auvzP -e ssh "${files[@]}" . 2>&1; then
  success "Successfully transferred ${#files[@]} file(s)"
else
  local exit_code=$?
  err "Some files failed to transfer (exit code: $exit_code)"
  warn "Check SSH connectivity and file permissions"
  exit $exit_code
fi
