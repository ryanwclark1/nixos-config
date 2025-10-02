#!/usr/bin/env bash
# Interactive Grep with FZF — live ripgrep integration + Neovim support

set -euo pipefail

# ---------- Colors ----------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly RESET='\033[0m'

# ---------- Globals ----------
SEARCH_TOOL=""     # rg|ag|ack|grep (tool name only)
SEARCH_BASE=""     # base command without the query
PREVIEW_CMD=""
EDITOR_CMD=""
declare -a GENERIC_OPTS=()  # generic flags the user requested

# ---------- Helpers ----------
err()  { printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2; }
info() { printf "${BLUE}[INFO]${RESET} %s\n" "$*"; }
warn() { printf "${YELLOW}[WARNING]${RESET} %s\n" "$*"; }

has() {
  local verbose=false
  if [[ ${1-} == '-v' ]]; then verbose=true; shift; fi
  for c in "$@"; do
    if ! command -v "${c%% *}" &>/dev/null; then
      [[ "$verbose" == true ]] && err "$c not found"
      return 1
    fi
  done
}

select_from() {
  local c
  for c; do
    if command -v "${c%% *}" &>/dev/null; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

# ---------- Editor / Neovim integration ----------
# Prefer an existing Neovim instance via nvr; fall back to nvim/vim/vi/nano.
init_editor_cmd() {
  if command -v nvr &>/dev/null; then
    # Use nvr only if a server exists; otherwise we'll spawn nvim below.
    if nvr --serverlist 2>/dev/null | grep -q .; then
      EDITOR_CMD="nvr --remote-silent"
      info "Using Neovim (nvr) remote"
      return 0
    fi
  fi

  # $EDITOR if valid, else try common editors
  local e="${EDITOR:-}"
  if [[ -n "$e" ]] && command -v "$e" &>/dev/null; then
    EDITOR_CMD="$e"
    info "Using editor: $EDITOR_CMD"
    return 0
  fi

  local picked
  picked=$(select_from nvim vim vi nano) || {
    err "No suitable editor found"
    return 1
  }
  EDITOR_CMD="$picked"
  info "Using editor: $EDITOR_CMD"
}

# Build the fzf enter binding to open at file:line:col.
# Uses nvr if EDITOR_CMD starts with 'nvr', otherwise spawns editor.
build_enter_bind() {
  # {1}=file {2}=line {3}=col (grep may not provide {3})
  if [[ "$EDITOR_CMD" == nvr* ]]; then
    # nvr edits in existing Neovim instance
    echo "enter:become($EDITOR_CMD +\"call cursor({2}, ({3} > 0 ? {3} : 1))\" {1})"
  else
    # spawn editor; nvim/vim accept multiple +cmds
    if [[ "${EDITOR_CMD##*/}" =~ ^(n?vim)$ ]]; then
      echo "enter:become($EDITOR_CMD +{2} +\"normal! \\|{3}\" {1})"
    else
      # basic editors: best effort line jump if supported (vi/vim handle +{line}, nano +{line},{col})
      if [[ "${EDITOR_CMD##*/}" == "nano" ]]; then
        echo "enter:become($EDITOR_CMD +{2},{3} {1})"
      else
        echo "enter:become($EDITOR_CMD +{2} {1})"
      fi
    fi
  fi
}

# ---------- Search command setup ----------
# Initialize tool & base command (no user opts, no query).
init_search_base() {
  # Choose tool priority
  if command -v rg &>/dev/null; then
    SEARCH_TOOL="rg"
    # --column gives {3}; --no-heading for clean file:line:col; --smart-case; include colors for preview
    SEARCH_BASE="rg --column --line-number --no-heading --color=always --smart-case --follow --glob='!{.git,node_modules,target,.svn,.hg}/*'"
  elif command -v ag &>/dev/null; then
    SEARCH_TOOL="ag"
    SEARCH_BASE="ag --column --line-numbers --nobreak --noheading --color --follow --ignore=.git --ignore=node_modules --ignore=target"
  elif command -v ack &>/dev/null; then
    SEARCH_TOOL="ack"
    # Note: ack supports --column and --line-number
    SEARCH_BASE="ack --column --line-number --color --smart-case --nogroup"
  else
    SEARCH_TOOL="grep"
    # grep lacks column numbers; we still set --line-number for {2}
    SEARCH_BASE="grep -RIn --binary-files=without-match --color=always --exclude-dir={.git,node_modules,target,.svn,.hg}"
  fi
  info "Search tool: $SEARCH_TOOL"
}

# Map generic flags to the selected tool's equivalent.
# Input: GENERIC_OPTS array
map_flags_for_tool() {
  local -a mapped=()
  for f in "${GENERIC_OPTS[@]}"; do
    case "$SEARCH_TOOL:$f" in
      rg:--ignore-case|grep:--ignore-case)                     mapped+=(-i) ;;
      ag:--ignore-case|ack:--ignore-case)                      mapped+=(--ignore-case) ;;

      rg:--word-regexp|ag:--word-regexp|ack:--word-regexp)     mapped+=(-w) ;;
      grep:--word-regexp)                                      mapped+=(-w) ;;

      rg:--fixed-strings|grep:--fixed-strings)                 mapped+=(-F) ;;
      ag:--fixed-strings)                                      mapped+=(-Q) ;;
      ack:--fixed-strings)                                     mapped+=(--literal) ;;

      rg:--invert-match|ag:--invert-match|ack:--invert-match|grep:--invert-match) mapped+=(-v) ;;

      rg:--hidden|ag:--hidden)                                 mapped+=(--hidden) ;;
      rg:--no-ignore|ag:--no-ignore)                           mapped+=(--no-ignore) ;;
      *)                                                       mapped+=("$f") ;;
    esac
  done
  printf '%s\n' "${mapped[@]}"
}

# Compose the final reload command used by fzf (no query appended here).
compose_reload_without_query() {
  local mapped
  mapfile -t mapped < <(map_flags_for_tool)
  # shellcheck disable=SC2086
  printf '%s %s' "$SEARCH_BASE" "${mapped[*]:-}"
}

# ---------- Preview setup ----------
init_preview_cmd() {
  if command -v bat &>/dev/null; then
    PREVIEW_CMD='bat --color=always --style=full --highlight-line {2} -- {1}'
  elif command -v highlight &>/dev/null; then
    PREVIEW_CMD='highlight -O ansi --line-numbers --line-number-length=3 --force -- {1} 2>/dev/null | sed -e "$(( {2} ))s/^/→ /"'
  else
    # awk fallback; highlight line {2} with arrow; ignore {3} safely if empty
    PREVIEW_CMD='awk -v ln="{2}" '\''{ n=NR; p=(n==ln)?"→ ":"  "; print p $0 }'\'' -- {1}'
  fi
}

# ---------- Help ----------
show_help() {
  cat << 'EOF'
Interactive Grep with FZF

USAGE:
  igr.sh [OPTIONS] [INITIAL_QUERY]

OPTIONS:
  -h, --help          Show help
  -i, --ignore-case   Case insensitive search
  -w, --word-regexp   Match whole words
  -F, --fixed-strings Treat pattern as literal string
  -v, --invert-match  Invert match
  --hidden            Include hidden files
  --no-ignore         Don't respect .gitignore

KEYS:
  Enter       Open in editor at line/col (Neovim via nvr if available)
  Ctrl-O      Open via xdg-open/open
  Ctrl-Y      Copy file:line to clipboard
  Ctrl-L      Toggle preview
  Ctrl-R      Reload
  ?           Help in preview
  Esc         Quit
EOF
}

# ---------- Main ----------
main() {
  local initial_query=""
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help) show_help; exit 0 ;;
      -i|--ignore-case)   GENERIC_OPTS+=(--ignore-case); shift ;;
      -w|--word-regexp)   GENERIC_OPTS+=(--word-regexp); shift ;;
      -F|--fixed-strings) GENERIC_OPTS+=(--fixed-strings); shift ;;
      -v|--invert-match)  GENERIC_OPTS+=(--invert-match); shift ;;
      --hidden)           GENERIC_OPTS+=(--hidden); shift ;;
      --no-ignore)        GENERIC_OPTS+=(--no-ignore); shift ;;
      --) shift; break ;;
      -*)
        err "Unknown option: $1"
        show_help
        exit 1
        ;;
      *)
        initial_query="$1"; shift; break ;;
    esac
  done

  has -v fzf || { err "fzf is required"; exit 1; }
  init_search_base
  init_preview_cmd
  init_editor_cmd

  # Build reload command (without the {q}); we append " -- {q}" so patterns beginning with '-' are safe.
  local RELOAD_BASE
  RELOAD_BASE=$(compose_reload_without_query)

  # fzf configuration
  local enter_bind; enter_bind=$(build_enter_bind)

  local -a fzf_cmd=(
    fzf
    --ansi
    --delimiter=':'
    --with-nth='1,2,3,4..'
    --query="$initial_query"
    --phony
    --header="Interactive Grep (${SEARCH_TOOL}) | Enter: open | Ctrl-O: open default | Ctrl-Y: copy | ? help"
    --preview="[[ -n {1} ]] && $PREVIEW_CMD"
    # Center the hit and give context; allow <80 columns to flip preview up
    --preview-window='right,60%,border-left,~4,+{2}+4/3,<80(up)'
    # Run a search immediately on start, and on every query change.
    --bind="start:reload:$RELOAD_BASE -- {q} || :"
    --bind="change:reload:$RELOAD_BASE -- {q} || :"
    # Editor open
    --bind="$enter_bind"
    # Extras
    --bind="ctrl-o:execute(xdg-open {1} 2>/dev/null || open {1} 2>/dev/null)"
    --bind="ctrl-y:execute-silent(echo {1}:{2} | wl-copy 2>/dev/null || echo {1}:{2} | xclip -selection clipboard 2>/dev/null || echo {1}:{2} | pbcopy 2>/dev/null)"
    --bind='?:preview:echo -e "KEYS:\n\nEnter - Open in editor at line/col\nCtrl-O - Open in default app\nCtrl-Y - Copy file:line\nCtrl-L - Toggle preview\nCtrl-R - Reload\nEsc - Quit\n\nSearch Tool: '"${SEARCH_TOOL}"'"'
    --bind="ctrl-l:toggle-preview"
    --bind="ctrl-r:reload:$RELOAD_BASE -- {q} || :"
  )

  # Execute FZF
  "${fzf_cmd[@]}" || {
    case $? in
      1) warn "No matches found" ;;
      2) err "fzf error occurred" ;;
      130) info "Cancelled" ;;
      *) err "Unknown error" ;;
    esac
  }
}

# If executed (not sourced)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
