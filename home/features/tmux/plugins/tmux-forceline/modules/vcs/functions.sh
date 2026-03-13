#!/usr/bin/env bash
# Pure VCS functions for tmux-forceline
# Source this file — not meant to be executed directly

# Guard: skip if already loaded via source_helpers.sh (which includes common.sh)
if [[ -z "${FL_VERSION:-}" ]]; then
    source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/pure_helpers.sh"
fi

# Default configurations
VCS_SHOW_SYMBOL="${FORCELINE_VCS_SHOW_SYMBOL:-yes}"
VCS_BRANCH_MAX_LEN="${FORCELINE_VCS_BRANCH_MAX_LEN:-20}"
VCS_TRUNCATE_SYMBOL="${FORCELINE_VCS_TRUNCATE_SYMBOL:-…}"

# Get working directory — accepts explicit dir, falls back to pwd
get_working_dir() {
    local dir="${1:-}"
    if [ -n "$dir" ] && [ -d "$dir" ]; then
        echo "$dir"
    else
        pwd
    fi
}

# Detect VCS type and root path
detect_vcs() {
    local current_dir
    current_dir=$(get_working_dir "${1:-}")

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
    local current_dir="${1:-$(pwd)}"
    local max_len="$2"
    local truncate_symbol="$3"

    if ! command_exists git; then
        return 1
    fi

    local branch
    branch=$(git -C "$current_dir" symbolic-ref --short HEAD 2>/dev/null)

    if [ -z "$branch" ]; then
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

# Get Git status counts (modified:staged:untracked:ahead:behind)
get_git_status() {
    local current_dir="${1:-$(pwd)}"

    if ! command_exists git || ! git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
        return 1
    fi

    local status_output modified staged untracked ahead behind
    status_output=$(git -C "$current_dir" status --porcelain=v1 2>/dev/null)

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

        if [[ "$index_status" =~ [MADRC] ]]; then
            staged=$((staged + 1))
        fi
        if [[ "$working_status" =~ [MD] ]]; then
            modified=$((modified + 1))
        fi
        if [ "$index_status" = "?" ]; then
            untracked=$((untracked + 1))
        fi
    done <<< "$status_output"

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

# Get VCS status with icon (returns: [icon]branch:modified:staged:untracked:ahead:behind:vcs_type)
get_vcs_status_with_icon() {
    local show_icon="$1"
    local working_dir="${2:-$(pwd)}"

    local vcs_info vcs_type vcs_root
    vcs_info=$(detect_vcs "$working_dir")
    vcs_type=$(echo "$vcs_info" | cut -d: -f1)
    vcs_root=$(echo "$vcs_info" | cut -d: -f2-)

    if [ "$vcs_type" = "none" ]; then
        return 1
    fi

    local icon=""
    if [ "$show_icon" = "yes" ]; then
        case "$vcs_type" in
            "git") icon="󰊢 " ;;
            "hg")  icon="󰘫 " ;;
            "svn") icon="󰚶 " ;;
        esac
    fi

    local branch status
    case "$vcs_type" in
        "git")
            branch=$(get_git_branch "$working_dir" "$VCS_BRANCH_MAX_LEN" "$VCS_TRUNCATE_SYMBOL")
            status=$(get_git_status "$working_dir")
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

# Format status counts for display
format_status_counts() {
    local status_data="$1"
    local show_symbols="$2"
    local show_zero="$3"

    local modified staged untracked ahead behind
    IFS=: read -r modified staged untracked ahead behind <<< "$status_data"

    local result=""
    local has_changes=false

    if [ "$staged" -gt 0 ] || [ "$show_zero" = "yes" ]; then
        if [ "$show_symbols" = "yes" ]; then result="${result}+${staged} "; else result="${result}S:${staged} "; fi
        has_changes=true
    fi
    if [ "$modified" -gt 0 ] || [ "$show_zero" = "yes" ]; then
        if [ "$show_symbols" = "yes" ]; then result="${result}±${modified} "; else result="${result}M:${modified} "; fi
        has_changes=true
    fi
    if [ "$untracked" -gt 0 ] || [ "$show_zero" = "yes" ]; then
        if [ "$show_symbols" = "yes" ]; then result="${result}?${untracked} "; else result="${result}U:${untracked} "; fi
        has_changes=true
    fi
    if [ "$ahead" -gt 0 ]; then
        if [ "$show_symbols" = "yes" ]; then result="${result}↑${ahead} "; else result="${result}A:${ahead} "; fi
        has_changes=true
    fi
    if [ "$behind" -gt 0 ]; then
        if [ "$show_symbols" = "yes" ]; then result="${result}↓${behind} "; else result="${result}B:${behind} "; fi
        has_changes=true
    fi

    if [ "$has_changes" = "false" ]; then
        if [ "$show_symbols" = "yes" ]; then result="✓"; else result="CLEAN"; fi
    else
        result=$(echo "$result" | sed 's/ $//')
    fi

    echo "$result"
}

# Get VCS status level (CLEAN, STAGED, DIVERGED, DIRTY)
get_vcs_status_level() {
    local status_data="$1"

    local modified staged untracked ahead behind
    IFS=: read -r modified staged untracked ahead behind <<< "$status_data"

    if [ "$modified" -gt 0 ] || [ "$untracked" -gt 0 ]; then
        echo "DIRTY"
    elif [ "$staged" -gt 0 ]; then
        echo "STAGED"
    elif [ "$ahead" -gt 0 ] || [ "$behind" -gt 0 ]; then
        echo "DIVERGED"
    else
        echo "CLEAN"
    fi
}

# Get VCS color based on repository state
get_vcs_color() {
    local color_type="${1:-bg}"
    local status_data="$2"
    local clean_fg="${3:-#{@fg\}}"
    local clean_bg="${4:-#{@success\}}"
    local staged_fg="${5:-#{@base00\}}"
    local staged_bg="${6:-#{@info\}}"
    local diverged_fg="${7:-#{@base00\}}"
    local diverged_bg="${8:-#{@warning\}}"
    local dirty_fg="${9:-#{@base00\}}"
    local dirty_bg="${10:-#{@error\}}"

    local status_level
    status_level=$(get_vcs_status_level "$status_data")

    case "$status_level" in
        "CLEAN")    if [ "$color_type" = "fg" ]; then echo "$clean_fg"; else echo "$clean_bg"; fi ;;
        "STAGED")   if [ "$color_type" = "fg" ]; then echo "$staged_fg"; else echo "$staged_bg"; fi ;;
        "DIVERGED") if [ "$color_type" = "fg" ]; then echo "$diverged_fg"; else echo "$diverged_bg"; fi ;;
        "DIRTY")    if [ "$color_type" = "fg" ]; then echo "$dirty_fg"; else echo "$dirty_bg"; fi ;;
        *)          if [ "$color_type" = "fg" ]; then echo "$clean_fg"; else echo "$clean_bg"; fi ;;
    esac
}
