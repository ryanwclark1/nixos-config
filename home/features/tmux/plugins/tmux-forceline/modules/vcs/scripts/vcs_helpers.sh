#!/usr/bin/env bash
# VCS Helper Functions for tmux-forceline v2.0
# Git repository detection and status monitoring

# Default configurations
VCS_SHOW_SYMBOL="${FORCELINE_VCS_SHOW_SYMBOL:-yes}"
VCS_BRANCH_MAX_LEN="${FORCELINE_VCS_BRANCH_MAX_LEN:-20}"
VCS_TRUNCATE_SYMBOL="${FORCELINE_VCS_TRUNCATE_SYMBOL:-…}"

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get current tmux pane working directory
get_tmux_cwd() {
    local tmux_pwd
    if [ -n "${TMUX:-}" ]; then
        tmux_pwd=$(tmux display-message -p "#{pane_current_path}" 2>/dev/null)
        if [ -n "$tmux_pwd" ] && [ -d "$tmux_pwd" ]; then
            echo "$tmux_pwd"
            return 0
        fi
    fi
    pwd
}

# Detect VCS type and root path
detect_vcs() {
    local current_dir
    current_dir=$(get_tmux_cwd)
    
    # Check for Git
    if command_exists git && git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
        local git_root
        git_root=$(git -C "$current_dir" rev-parse --show-toplevel 2>/dev/null)
        echo "git:$git_root"
        return 0
    fi
    
    # Check for Mercurial
    local dir="$current_dir"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.hg" ]; then
            echo "hg:$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    
    # Check for SVN
    if command_exists svn; then
        local svn_info
        svn_info=$(svn info "$current_dir" 2>/dev/null)
        if [ $? -eq 0 ]; then
            local svn_root
            svn_root=$(echo "$svn_info" | grep "Working Copy Root Path:" | cut -d: -f2- | sed 's/^ *//')
            echo "svn:$svn_root"
            return 0
        fi
    fi
    
    echo "none:"
    return 1
}

# Get Git branch name
get_git_branch() {
    local current_dir max_len truncate_symbol
    current_dir=$(get_tmux_cwd)
    max_len="$1"
    truncate_symbol="$2"
    
    if ! command_exists git; then
        return 1
    fi
    
    local branch
    branch=$(git -C "$current_dir" symbolic-ref --short HEAD 2>/dev/null)
    
    if [ -z "$branch" ]; then
        # Try to get detached HEAD info
        branch=$(git -C "$current_dir" describe --tags --exact-match HEAD 2>/dev/null)
        if [ -z "$branch" ]; then
            branch=$(git -C "$current_dir" rev-parse --short HEAD 2>/dev/null)
            if [ -n "$branch" ]; then
                branch="@$branch"
            fi
        fi
    fi
    
    if [ -z "$branch" ]; then
        return 1
    fi
    
    # Truncate if necessary
    if [ -n "$max_len" ] && [ "${#branch}" -gt "$max_len" ]; then
        branch="${branch:0:$((max_len-1))}$truncate_symbol"
    fi
    
    echo "$branch"
}

# Get Git status counts
get_git_status() {
    local current_dir
    current_dir=$(get_tmux_cwd)
    
    if ! command_exists git || ! git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
        return 1
    fi
    
    local status_output modified staged untracked ahead behind
    status_output=$(git -C "$current_dir" status --porcelain=v1 2>/dev/null)
    
    # Count file changes
    modified=0
    staged=0
    untracked=0
    
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            continue
        fi
        
        local index_status working_status
        index_status="${line:0:1}"
        working_status="${line:1:1}"
        
        # Count staged changes
        if [[ "$index_status" =~ [MADRC] ]]; then
            staged=$((staged + 1))
        fi
        
        # Count working directory changes
        if [[ "$working_status" =~ [MD] ]]; then
            modified=$((modified + 1))
        fi
        
        # Count untracked files
        if [ "$index_status" = "?" ]; then
            untracked=$((untracked + 1))
        fi
    done <<< "$status_output"
    
    # Get ahead/behind info
    ahead=0
    behind=0
    local upstream_status
    upstream_status=$(git -C "$current_dir" status --porcelain=v1 --branch 2>/dev/null | head -1)
    
    if [[ "$upstream_status" =~ ahead\ ([0-9]+) ]]; then
        ahead="${BASH_REMATCH[1]}"
    fi
    
    if [[ "$upstream_status" =~ behind\ ([0-9]+) ]]; then
        behind="${BASH_REMATCH[1]}"
    fi
    
    echo "$modified:$staged:$untracked:$ahead:$behind"
}

# Get VCS status with icon
get_vcs_status_with_icon() {
    local show_icon="$1"
    local vcs_info branch status
    
    vcs_info=$(detect_vcs)
    local vcs_type vcs_root
    vcs_type=$(echo "$vcs_info" | cut -d: -f1)
    vcs_root=$(echo "$vcs_info" | cut -d: -f2-)
    
    if [ "$vcs_type" = "none" ]; then
        return 1
    fi
    
    local icon=""
    if [ "$show_icon" = "yes" ]; then
        case "$vcs_type" in
            "git")
                icon="󰊢 "
                ;;
            "hg")
                icon="󰘫 "
                ;;
            "svn")
                icon="󰚶 "
                ;;
        esac
    fi
    
    case "$vcs_type" in
        "git")
            branch=$(get_git_branch "$VCS_BRANCH_MAX_LEN" "$VCS_TRUNCATE_SYMBOL")
            status=$(get_git_status)
            ;;
        *)
            branch="unknown"
            status="0:0:0:0:0"
            ;;
    esac
    
    if [ -n "$branch" ]; then
        echo "${icon}${branch}:${status}:${vcs_type}"
        return 0
    fi
    
    return 1
}