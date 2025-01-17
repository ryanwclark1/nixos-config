#!/usr/bin/env bash

declare -A aliases
declare -A helptext

has() {
  local v c
  if [[ $1 = '-v' ]]; then
    v=1
    shift
  fi
  for c; do c="${c%% *}"
    if ! command -v "$c" &> /dev/null; then
      (( v > 0 )) && err "$c not found"
      return 1
    fi
  done
}

aliases[h]=help
aliases[-h]=help
aliases[--help]=help
helptext[help]='show this help'
subcmd_help() {
  local formattedhelptext

  formattedhelptext=$(for c in "${subcmds_avail[@]}"; do
    printf "  %s\n    %s\n" "$c" "${helptext[$c]}"
  done)
  LESS=-FEXR less <<-HELP
$0 <COMMAND>

${formattedhelptext}
HELP
}

helptext[ps]='show a list of running processes'
subcmd_ps() {
  fzf \
    --bind='start:reload:docker ps' \
    --bind='enter:execute:docker exec -it {1} sh' \
    --bind='ctrl-d:execute-silent(docker stop {1})+reload:docker ps' \
    --bind='?:toggle-preview' \
    --bind='ctrl-l:clear-screen+reload:docker ps' \
    --preview='docker logs -f {1}' \
    --header='<Enter> opens sh inside container, <F9> to kill' \
    --reverse \
    --height=100% \
    --header-lines=1 \
    --preview-window=cycle,follow,80%:down
}

mapfile -t subcmds_avail < <(compgen -A function | awk '/^subcmd_/ { sub(/^subcmd_/, "", $0); print }')

nocmd() {
  cmd=$(for c in "${subcmds_avail[@]}"; do
  printf "$c\t${help}\t${helptext[$c]}\n"
done)
  subcmd_$(column -t -s $'\t' <<< "$cmd" | fzf | awk '{print $1}')
}

if (( $# < 1 )); then
  nocmd
  exit 1
elif has "subcmd_$1"; then
  subcmd="subcmd_$1"
  shift
  "$subcmd" "$@"
elif [[ -v aliases[$1] ]]; then
  subcmd=subcmd_${aliases[$1]}
  shift
  "$subcmd" "$@"
else
  echo 'unknown command'
  subcmd_help
  exit 1
fi