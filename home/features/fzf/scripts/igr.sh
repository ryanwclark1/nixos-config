#!/usr/bin/env bash

# Interactive Grep with FZF
# Real-time search with live preview and multiple actions

set -euo pipefail

# Catppuccin Frappé colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly RESET='\033[0m'

# Global variables
declare -g SEARCH_CMD=""
declare -g PREVIEW_CMD=""
declare -g EDITOR_CMD=""

# Helper functions
err() {
    printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2
}

info() {
    printf "${BLUE}[INFO]${RESET} %s\n" "$*"
}

warn() {
    printf "${YELLOW}[WARNING]${RESET} %s\n" "$*"
}

has() {
    local verbose=false
    if [[ $1 == '-v' ]]; then
        verbose=true
        shift
    fi
    for cmd in "$@"; do
        if ! command -v "${cmd%% *}" &>/dev/null; then
            [[ "$verbose" == true ]] && err "$cmd not found"
            return 1
        fi
    done
}

# Select best available command from options
select_from() {
    local cmd
    for cmd; do
        if command -v "${cmd%% *}" &>/dev/null; then
            echo "$cmd"
            return 0
        fi
    done
    return 1
}

# Initialize search command (prefer ripgrep)
init_search_cmd() {
    SEARCH_CMD=$(select_from \
        'rg --line-number --color=always --smart-case --hidden --follow' \
        'ag --line-numbers --color --smart-case --hidden --follow' \
        'ack --color --smart-case --line' \
        'grep -rn --color=always'
    )
    
    if [[ -z "$SEARCH_CMD" ]]; then
        err "No search tool found. Please install ripgrep, ag, ack, or ensure grep is available"
        return 1
    fi
    
    # Add common exclusions for better performance
    case "${SEARCH_CMD%% *}" in
        rg)
            SEARCH_CMD="$SEARCH_CMD --glob='!{.git,node_modules,target,.svn,.hg}/*'"
            ;;
        ag)
            SEARCH_CMD="$SEARCH_CMD --ignore=.git --ignore=node_modules --ignore=target"
            ;;
        grep)
            SEARCH_CMD="$SEARCH_CMD --exclude-dir={.git,node_modules,target,.svn,.hg}"
            ;;
    esac
}

# Initialize preview command (prefer bat)
init_preview_cmd() {
    if command -v bat &>/dev/null; then
        PREVIEW_CMD='bat --color=always --style=header,numbers --highlight-line {2} {1}'
    elif command -v highlight &>/dev/null; then
        PREVIEW_CMD='highlight -O ansi --line-numbers --line-number-length=3 {1} 2>/dev/null | sed "{2}s/^/→ /"'
    else
        # Fallback with awk for line highlighting
        PREVIEW_CMD='awk "BEGIN{a=\"{2}\";gsub(\"'"'"'\", \"\", a)} NR==(a+0){print \"→ \" \$0; next} {print \"  \" \$0}" {1}'
    fi
}

# Initialize editor command
init_editor_cmd() {
    local editor="${EDITOR:-}"
    
    if [[ -n "$editor" ]] && command -v "$editor" &>/dev/null; then
        EDITOR_CMD="$editor"
        return 0
    fi
    
    # Try common editors
    for editor in nvim vim vi nano; do
        if command -v "$editor" &>/dev/null; then
            EDITOR_CMD="$editor"
            return 0
        fi
    done
    
    err "No suitable editor found"
    return 1
}

# Show help
show_help() {
    cat << 'EOF'
Interactive Grep with FZF

USAGE:
    igr.sh [OPTIONS] [INITIAL_QUERY]

OPTIONS:
    -h, --help          Show this help message
    -i, --ignore-case   Case insensitive search
    -w, --word-regexp   Match whole words only
    -F, --fixed-strings Treat pattern as literal string
    -v, --invert-match  Show non-matching lines
    --hidden            Include hidden files
    --no-ignore         Don't respect .gitignore

KEYBINDINGS:
    <Enter>             Open file at line in editor
    <Ctrl-O>            Open file in default application
    <Ctrl-Y>            Copy file:line to clipboard
    <Ctrl-L>            Toggle preview window
    <Ctrl-R>            Reload search results
    <Ctrl-T>            Toggle search tool
    <Esc>               Quit
    ?                   Show help in preview

EXAMPLES:
    igr.sh "function"       # Interactive search for "function"
    igr.sh -i "todo"        # Case insensitive search
    igr.sh -w "class"       # Whole word search
    igr.sh --hidden "config" # Include hidden files

FEATURES:
    - Real-time search as you type
    - Multiple search tool support (rg, ag, ack, grep)
    - Intelligent preview with syntax highlighting
    - Multiple editor support
    - Clipboard integration
EOF
}

# Main interactive search function
main() {
    local initial_query=""
    local search_opts=()
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -i|--ignore-case)
                search_opts+=(--ignore-case)
                shift
                ;;
            -w|--word-regexp)
                search_opts+=(--word-regexp)
                shift
                ;;
            -F|--fixed-strings)
                search_opts+=(--fixed-strings)
                shift
                ;;
            -v|--invert-match)
                search_opts+=(--invert-match)
                shift
                ;;
            --hidden)
                search_opts+=(--hidden)
                shift
                ;;
            --no-ignore)
                search_opts+=(--no-ignore)
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                err "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                initial_query="$1"
                shift
                break
                ;;
        esac
    done
    
    # Check dependencies
    if ! has -v fzf; then
        err "This script requires fzf to be installed"
        exit 1
    fi
    
    # Initialize commands
    if ! init_search_cmd; then
        exit 1
    fi
    
    if ! init_preview_cmd; then
        exit 1
    fi
    
    if ! init_editor_cmd; then
        exit 1
    fi
    
    # Add search options to command
    if [[ ${#search_opts[@]} -gt 0 ]]; then
        SEARCH_CMD="$SEARCH_CMD ${search_opts[*]}"
    fi
    
    info "Using search tool: ${SEARCH_CMD%% *}"
    [[ -n "$initial_query" ]] && info "Initial query: $initial_query"
    
    # Create FZF command
    local fzf_cmd=(
        fzf
        --ansi
        --delimiter=:
        --query="$initial_query"
        --phony
        --preview="[[ -n {1} ]] && $PREVIEW_CMD"
        --preview-window='right,60%,border-left,+{2}+3/3,~3'
        --header="Interactive Grep | <Enter> edit | <Ctrl-O> open | <Ctrl-Y> copy | ? help"
        --bind="change:reload:$SEARCH_CMD {q} || true"
        --bind="start:reload:$SEARCH_CMD {q} || true"
        --bind="enter:become($EDITOR_CMD {1} +{2})"
        --bind="ctrl-o:execute(xdg-open {1} 2>/dev/null || open {1} 2>/dev/null)"
        --bind="ctrl-y:execute-silent(echo {1}:{2} | wl-copy || echo {1}:{2} | xclip -selection clipboard 2>/dev/null || echo {1}:{2} | pbcopy 2>/dev/null)"
        --bind="ctrl-l:toggle-preview"
        --bind="ctrl-r:reload:$SEARCH_CMD {q} || true"
        --bind="esc:cancel"
        --bind='?:preview:echo -e "KEYBINDINGS:\n\n<Enter> - Open file at line in editor\n<Ctrl-O> - Open file in default application\n<Ctrl-Y> - Copy file:line to clipboard\n<Ctrl-L> - Toggle preview window\n<Ctrl-R> - Reload search results\n<Esc> - Quit\n? - Show this help\n\nSEARCH TOOL: '"${SEARCH_CMD%% *}"'"'
    )
    
    # Execute FZF
    "${fzf_cmd[@]}" || {
        case $? in
            1) warn "No matches found" ;;
            2) err "FZF error occurred" ;;
            130) info "Search cancelled by user" ;;
            *) err "Unknown error occurred" ;;
        esac
    }
}

# Handle if sourced vs executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi