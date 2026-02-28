#!/usr/bin/env bash

set -euo pipefail

# Ensure we are actually running under Bash (not sh/zsh/ash)
if [[ -z "${BASH_VERSION:-}" ]]; then
  echo "[ERROR] This script must be run with bash" >&2
  exit 1
fi

# Colors for better readability
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Declare associative arrays
declare -A aliases
declare -A helptext

# Helper functions
err() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
}

info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*"
}

warn() {
  echo -e "${YELLOW}[WARNING]${NC} $*"
}

has() {
  local v=0 c
  if [[ ${1:-} == '-v' ]]; then
    v=1
    shift
  fi
  for c; do
    c="${c%% *}"
    if ! command -v "$c" &> /dev/null; then
      (( v > 0 )) && err "$c not found"
      return 1
    fi
  done
  return 0
}

# Check dependencies
check_deps() {
  if ! has -v fzf; then
    err "fzf is required but not found"
    err "Install fzf: nix-env -iA nixos.fzf"
    exit 1
  fi

  if ! has -v docker; then
    err "docker is required but not found"
    err "Install docker: nix-env -iA nixos.docker"
    exit 1
  fi

  # Check if Docker daemon is running
  if ! docker info &>/dev/null; then
    err "Cannot connect to Docker daemon"
    err "Is Docker running? Try: sudo systemctl start docker"
    err "Or check: docker info"
    exit 1
  fi
}

# Command aliases
aliases[h]=help
aliases[-h]=help
aliases[--help]=help
aliases[l]=logs
aliases[i]=images
aliases[v]=volumes
aliases[n]=networks
aliases[e]=exec
aliases[c]=compose

# Help texts
helptext[help]='Show this help message'
helptext[ps]='Show a list of running containers with interactive management'
helptext[logs]='Search and view container logs interactively'
helptext[images]='Manage Docker images interactively'
helptext[volumes]='Manage Docker volumes interactively'
helptext[networks]='Manage Docker networks interactively'
helptext[exec]='Execute commands in containers'
helptext[compose]='Manage Docker Compose projects'

# Help command
subcmd_help() {
  local formattedhelptext

  formattedhelptext=$(
    for c in "${subcmds_avail[@]}"; do
      printf "  ${GREEN}%-10s${NC}%s\n" "$c" "${helptext[$c]}"
    done
  )

  cat <<-HELP
${BLUE}Docker FZF Interactive CLI${NC}

${YELLOW}USAGE:${NC}
  $0 <COMMAND>

${YELLOW}AVAILABLE COMMANDS:${NC}
${formattedhelptext}

${YELLOW}ALIASES:${NC}
  ${GREEN}h, -h, --help${NC} = help
  ${GREEN}l${NC} = logs
  ${GREEN}i${NC} = images
  ${GREEN}v${NC} = volumes
  ${GREEN}n${NC} = networks
  ${GREEN}e${NC} = exec
  ${GREEN}c${NC} = compose
HELP
}

# Process management command
subcmd_ps() {
  local header_lines=1

  if ! docker ps &>/dev/null; then
    err "Cannot connect to Docker daemon"
    err "Is Docker running? Try: sudo systemctl start docker"
    return 1
  fi

  local header="${GREEN}<Enter>${NC} opens shell, ${YELLOW}<Ctrl-R>${NC} restart, ${RED}<Ctrl-D>${NC} stop, ${BLUE}<Ctrl-L>${NC} logs toggle, ${GREEN}<Ctrl-I>${NC} inspect, ${YELLOW}?${NC} help"

  local reload_cmd='docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}\t{{.Ports}}" 2>/dev/null || echo "Error: Cannot connect to Docker daemon"'

  fzf \
    --bind="start:reload:$reload_cmd" \
    --bind='enter:execute:(docker exec -it {1} sh 2>/dev/null || docker exec -it {1} bash 2>/dev/null || docker exec -it {1} /bin/sh 2>/dev/null || echo "Failed to open shell - container may not have sh/bash")' \
    --bind="ctrl-d:execute-silent(if docker stop {1} 2>/dev/null; then echo 'Stopped {1}'; else echo 'Failed to stop {1}'; fi)+reload:$reload_cmd" \
    --bind="ctrl-r:execute-silent(if docker restart {1} 2>/dev/null; then echo 'Restarted {1}'; else echo 'Failed to restart {1}'; fi)+reload:$reload_cmd" \
    --bind="ctrl-k:execute-silent(if docker kill {1} 2>/dev/null; then echo 'Killed {1}'; else echo 'Failed to kill {1}'; fi)+reload:$reload_cmd" \
    --bind='ctrl-i:execute:(docker inspect {1} 2>/dev/null | less || echo "Failed to inspect container - check container ID")' \
    --bind='ctrl-l:toggle-preview' \
    --bind='?:preview:echo -e "KEYBINDINGS:\n\n<Enter> - Open shell in container\n<Ctrl-D> - Stop container\n<Ctrl-R> - Restart container\n<Ctrl-K> - Kill container\n<Ctrl-I> - Inspect container\n<Ctrl-L> - Toggle logs view\n? - Show this help"' \
    --bind='escape:cancel' \
    --preview='docker logs --tail 100 {1} 2>&1 || echo "No logs available or container not found"' \
    --header="$header" \
    --reverse \
    --height=100% \
    --header-lines="$header_lines" \
    --preview-window=down:60%:wrap \
    --ansi \
    +m
}

# Log viewing command
subcmd_logs() {
  local header_lines=1

  if ! docker ps -a &>/dev/null; then
    err "Cannot connect to Docker daemon"
    err "Is Docker running? Try: sudo systemctl start docker"
    return 1
  fi

  local header="${GREEN}<Enter>${NC} follow logs, ${YELLOW}<Ctrl-A>${NC} all logs, ${GREEN}<Ctrl-T>${NC} tail, ${BLUE}<Ctrl-S>${NC} search"

  # First select container
  local container
  container=$(
    docker ps -a --format "{{.ID}}\t{{.Names}}\t{{.Status}}" |
      fzf --header="Select container to view logs" --height=50% --reverse --no-preview |
      awk '{print $1}'
  )

  [[ -z "${container:-}" ]] && return 0

  # Validate container exists
  if ! docker ps -a --format "{{.ID}}" | grep -q "^${container}$"; then
    err "Container $container not found"
    return 1
  fi

  # Then view logs with options
  docker logs --tail 100 "$container" 2>&1 |
    fzf \
      --bind="enter:execute:(docker logs -f $container 2>&1 | less +F || echo 'Failed to follow logs - container may have stopped')" \
      --bind="ctrl-a:execute:(docker logs $container 2>&1 | less || echo 'Failed to load logs')" \
      --bind="ctrl-t:execute:read -p 'How many lines to tail? ' n && (docker logs --tail \$n $container 2>&1 | less || echo 'Failed to load logs')" \
      --bind="ctrl-s:execute:read -p 'Search term: ' s && (docker logs $container 2>&1 | grep -i \"\$s\" | less || echo 'No matches found')" \
      --header="$header" \
      --reverse \
      --height=100% \
      --ansi
}

# Images management command
subcmd_images() {
  local header_lines=1

  if ! docker images &>/dev/null; then
    err "Cannot connect to Docker daemon"
    err "Is Docker running? Try: sudo systemctl start docker"
    return 1
  fi

  local header="${GREEN}<Enter>${NC} inspect, ${RED}<Ctrl-D>${NC} delete, ${YELLOW}<Ctrl-R>${NC} run, ${BLUE}<Ctrl-H>${NC} history"

  local reload_cmd='docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}\t{{.CreatedSince}}" 2>/dev/null || echo "Error: Cannot connect to Docker daemon"'

  fzf \
    --bind="start:reload:$reload_cmd" \
    --bind='enter:execute:(docker inspect {3} 2>/dev/null | less || echo "Failed to inspect image - check image ID")' \
    --bind='ctrl-d:execute-silent(if docker rmi {3} 2>/dev/null; then echo "Deleted {1}:{2}"; else echo "Failed to delete {1}:{2} - may be in use"; fi)+reload:'"$reload_cmd" \
    --bind='ctrl-r:execute:read -p "Run command (e.g., -it --rm): " opts && (docker run $opts {1}:{2} 2>&1 || echo "Failed to run image")' \
    --bind='ctrl-h:execute:(docker history {3} 2>/dev/null | less || echo "Failed to show history")' \
    --bind='?:preview:echo -e "KEYBINDINGS:\n\n<Enter> - Inspect image\n<Ctrl-D> - Delete image\n<Ctrl-R> - Run image\n<Ctrl-H> - Show history\n? - Show this help"' \
    --header="$header" \
    --reverse \
    --height=100% \
    --header-lines="$header_lines" \
    --ansi
}

# Volumes management command
subcmd_volumes() {
  local header_lines=1

  if ! docker volume ls &>/dev/null; then
    err "Cannot connect to Docker daemon. Is Docker running?"
    return 1
  fi

  local header="${GREEN}<Enter>${NC} inspect, ${RED}<Ctrl-D>${NC} delete, ${YELLOW}<Ctrl-P>${NC} prune unused"

  fzf \
    --bind='start:reload:docker volume ls' \
    --bind='enter:execute:docker volume inspect {1} | less' \
    --bind='ctrl-d:execute-silent(docker volume rm {1})+reload:docker volume ls' \
    --bind='ctrl-p:execute-silent(docker volume prune -f)+reload:docker volume ls' \
    --bind='?:preview:echo -e "KEYBINDINGS:\n\n<Enter> - Inspect volume\n<Ctrl-D> - Delete volume\n<Ctrl-P> - Prune unused volumes\n? - Show this help"' \
    --header="$header" \
    --reverse \
    --height=100% \
    --header-lines="$header_lines" \
    --ansi
}

# Networks management command
subcmd_networks() {
  local header_lines=1

  if ! docker network ls &>/dev/null; then
    err "Cannot connect to Docker daemon. Is Docker running?"
    return 1
  fi

  local header="${GREEN}<Enter>${NC} inspect, ${RED}<Ctrl-D>${NC} delete, ${YELLOW}<Ctrl-P>${NC} prune unused"

  fzf \
    --bind='start:reload:docker network ls' \
    --bind='enter:execute:docker network inspect {2} | less' \
    --bind='ctrl-d:execute-silent(docker network rm {2})+reload:docker network ls' \
    --bind='ctrl-p:execute-silent(docker network prune -f)+reload:docker network ls' \
    --bind='?:preview:echo -e "KEYBINDINGS:\n\n<Enter> - Inspect network\n<Ctrl-D> - Delete network\n<Ctrl-P> - Prune unused networks\n? - Show this help"' \
    --header="$header" \
    --reverse \
    --height=100% \
    --header-lines="$header_lines" \
    --ansi
}

# Exec command
subcmd_exec() {
  local header_lines=1

  if ! docker ps &>/dev/null; then
    err "Cannot connect to Docker daemon. Is Docker running?"
    return 1
  fi

  # First select container
  local container
  container=$(
    docker ps --format "{{.ID}}\t{{.Names}}\t{{.Image}}" |
      fzf --header="Select container to execute command in" --height=50% --reverse --no-preview |
      awk '{print $1}'
  )

  [[ -z "${container:-}" ]] && return 0

  # Then get command to execute
  local cmd
  read -rp "Command to execute (default: sh): " cmd
  cmd=${cmd:-sh}

  # Execute command
  docker exec -it "$container" $cmd
}

# Docker Compose command
subcmd_compose() {
  local header_lines=1
  local -a compose_files=()

  # Find docker-compose files in current directory (grouped names)
  while IFS= read -r file; do
    compose_files+=("$file")
  done < <(find . -maxdepth 2 \( -name "docker-compose*.yml" -o -name "compose*.yml" \) | sort)

  if [[ ${#compose_files[@]} -eq 0 ]]; then
    err "No Docker Compose files found in the current directory"
    return 1
  fi

  # Select compose file if there are multiple
  local compose_file
  if [[ ${#compose_files[@]} -eq 1 ]]; then
    compose_file="${compose_files[0]}"
  else
    compose_file=$(
      printf "%s\n" "${compose_files[@]}" |
        fzf --header="Select Docker Compose file" --height=50% --reverse --no-preview
    )
  fi

  [[ -z "${compose_file:-}" ]] && return 0

  # Select action
  local action
  action=$(
    echo -e "up\ndown\nps\nlogs\nrestart\npull\nbuild" |
      fzf --header="Select Docker Compose action" --height=50% --reverse --no-preview
  )
  [[ -z "${action:-}" ]] && return 0

  # Execute action
  case "$action" in
    up)
      local detach
      read -rp "Run in detached mode? (y/n): " detach
      if [[ "$detach" == "y" ]]; then
        docker compose -f "$compose_file" up -d
      else
        docker compose -f "$compose_file" up
      fi
      ;;
    logs)
      local service
      service=$(docker compose -f "$compose_file" ps --services |
        fzf --header="Select service to view logs" --height=50% --reverse --no-preview)
      [[ -z "${service:-}" ]] && return 0
      docker compose -f "$compose_file" logs -f "$service"
      ;;
    restart|down|ps|pull|build)
      docker compose -f "$compose_file" "$action"
      ;;
  esac
}

# -------- Subcommand discovery (no compgen) --------
# Build the list of available subcommands based on defined functions
subcmds_avail=()
while IFS= read -r line; do
  # 'declare -F' outputs lines like: "declare -f subcmd_ps"
  # Grab the last whitespace-separated field for portability.
  name=${line##* }
  if [[ $name == subcmd_* ]]; then
    subcmds_avail+=("${name#subcmd_}")
  fi
done < <(declare -F)

# No command selected - Interactive menu
nocmd() {
  check_deps

  local formatted_list="" selected command
  for c in "${subcmds_avail[@]}"; do
    formatted_list+="${GREEN}$c${NC}\t${helptext[$c]}\n"
  done

  # Use fzf with proper options to avoid bat preview issues
  selected=$(echo -e "$formatted_list" |
    column -t -s $'\t' |
    fzf --ansi \
        --height=50% \
        --reverse \
        --header="Select Docker FZF command:" \
        --no-preview)  # Disable preview to avoid bat errors in some envs

  if [[ -n "${selected:-}" ]]; then
    # Extract just the command (first word) without colors
    command=$(echo "$selected" | sed 's/\x1B\[[0-9;]*[JKmsu]//g' | awk '{print $1}')
    if type "subcmd_$command" &>/dev/null; then
      "subcmd_$command"
    fi
  fi
}

# Main execution logic
check_deps

if (( $# < 1 )); then
  nocmd
  exit 0
elif type "subcmd_${1}" &>/dev/null; then
  subcmd="subcmd_${1}"
  shift
  "$subcmd" "$@"
elif [[ -v aliases[$1] ]]; then
  subcmd="subcmd_${aliases[$1]}"
  shift
  "$subcmd" "$@"
else
  err "Unknown command: $1"
  subcmd_help
  exit 1
fi
