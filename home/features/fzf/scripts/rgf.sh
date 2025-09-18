#!/usr/bin/env bash

# Enhanced Ripgrep + FZF File Search
# Intelligent file search with preview and multiple editor support

set -euo pipefail

# Catppuccin Frappé colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly RESET='\033[0m'

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

# Get preferred editor
get_editor() {
    local editor
    editor="${EDITOR:-}"
    
    if [[ -n "$editor" ]] && command -v "$editor" &>/dev/null; then
        echo "$editor"
        return 0
    fi
    
    # Try common editors in order of preference
    for editor in nvim vim vi nano; do
        if command -v "$editor" &>/dev/null; then
            echo "$editor"
            return 0
        fi
    done
    
    err "No suitable editor found"
    return 1
}

# Get preview command
get_preview_cmd() {
    if command -v bat &>/dev/null; then
        echo "bat --color=always --style=numbers,changes --highlight-line {2} {1}"
    elif command -v highlight &>/dev/null; then
        echo "highlight -O ansi -l {1} 2>/dev/null | sed -n '{2}p' | head -1; highlight -O ansi -l {1} 2>/dev/null"
    else
        echo "sed -n '{2}p' {1} | head -1; cat {1}"
    fi
}

# Show help
show_help() {
    cat << 'EOF'
Enhanced Ripgrep + FZF File Search

USAGE:
    rgf.sh [OPTIONS] [SEARCH_PATTERN]

OPTIONS:
    -h, --help          Show this help message
    -i, --ignore-case   Case insensitive search
    -t, --type TYPE     Filter by file type (e.g., py, js, rs)
    -g, --glob PATTERN  Include files matching glob pattern
    -v, --invert        Show lines that don't match
    --hidden            Search hidden files
    --no-ignore         Don't respect .gitignore

KEYBINDINGS:
    <Enter>             Open file at line in editor
    <Ctrl-O>            Open file in default editor
    <Ctrl-Y>            Copy file path to clipboard
    <Ctrl-L>            Toggle line numbers in preview
    <Ctrl-/>            Toggle preview window
    ?                   Show help in preview

EXAMPLES:
    rgf.sh "function"           # Search for "function"
    rgf.sh -t py "class"        # Search in Python files only
    rgf.sh -i "todo"            # Case insensitive search
    rgf.sh --hidden "config"    # Include hidden files
EOF
}

# Main search function
main() {
    local search_pattern=""
    local rg_opts=()
    local fzf_opts=()
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -i|--ignore-case)
                rg_opts+=(--ignore-case)
                shift
                ;;
            -t|--type)
                rg_opts+=(--type "$2")
                shift 2
                ;;
            -g|--glob)
                rg_opts+=(--glob "$2")
                shift 2
                ;;
            -v|--invert)
                rg_opts+=(--invert-match)
                shift
                ;;
            --hidden)
                rg_opts+=(--hidden)
                shift
                ;;
            --no-ignore)
                rg_opts+=(--no-ignore)
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
                search_pattern="$1"
                shift
                break
                ;;
        esac
    done
    
    # Check dependencies
    if ! has -v rg fzf; then
        err "This script requires ripgrep (rg) and fzf to be installed"
        exit 1
    fi
    
    # Get editor
    local editor
    if ! editor=$(get_editor); then
        exit 1
    fi
    
    # Get preview command
    local preview_cmd
    preview_cmd=$(get_preview_cmd)
    
    # Prompt for search pattern if not provided
    if [[ -z "$search_pattern" ]]; then
        printf "${BLUE}Enter search pattern: ${RESET}"
        read -r search_pattern
        [[ -z "$search_pattern" ]] && exit 0
    fi
    
    # Build ripgrep command
    local rg_cmd=(
        rg
        --color=always
        --line-number
        --no-heading
        --smart-case
        "${rg_opts[@]}"
        "$search_pattern"
    )
    
    # Additional patterns from remaining args
    [[ $# -gt 0 ]] && rg_cmd+=("$@")
    
    info "Searching for: $search_pattern"
    
    # Execute search with FZF
    local selected
    selected=$("${rg_cmd[@]}" 2>/dev/null |
        fzf --ansi \
            --color "hl:-1:underline,hl+:-1:underline:reverse" \
            --delimiter : \
            --preview "$preview_cmd" \
            --preview-window 'right,60%,border-left,+{2}+3/3,~3' \
            --header "Search: $search_pattern | <Enter> open | <Ctrl-O> editor | <Ctrl-Y> copy | ? help" \
            --bind "enter:become($editor {1} +{2})" \
            --bind "ctrl-o:execute($editor {1} +{2})" \
            --bind "ctrl-y:execute-silent(echo {1}:{2} | wl-copy || echo {1}:{2} | xclip -selection clipboard 2>/dev/null || echo {1}:{2} | pbcopy 2>/dev/null)" \
            --bind "ctrl-l:toggle-preview" \
            --bind "ctrl-/:change-preview-window(right,60%,border-left|down,60%,border-top|hidden|)" \
            --bind '?:preview:echo -e "KEYBINDINGS:\n\n<Enter> - Open file at line in editor\n<Ctrl-O> - Open file in editor\n<Ctrl-Y> - Copy file:line to clipboard\n<Ctrl-L> - Toggle preview\n<Ctrl-/> - Change preview window\n? - Show this help"' \
    ) || {
        case $? in
            1) warn "No matches found for: $search_pattern" ;;
            2) err "FZF error occurred" ;;
            130) info "Search cancelled by user" ;;
            *) err "Unknown error occurred" ;;
        esac
        exit $?
    }
    
    # If we get here without becoming an editor, something went wrong
    [[ -n "$selected" ]] || exit 1
}

# Handle if sourced vs executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi