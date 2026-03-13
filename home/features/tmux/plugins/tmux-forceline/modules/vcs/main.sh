#!/usr/bin/env bash
set -euo pipefail

source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/source_helpers.sh"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$CURRENT_DIR/functions.sh"

cmd="${1:-branch}"; shift || true

case "$cmd" in
    branch)
        working_dir="${1:-}"
        if [[ -z "$working_dir" ]]; then
            working_dir="$(tmux display-message -p '#{pane_current_path}' 2>/dev/null || pwd)"
        fi
        show_icon="${2:-$(get_tmux_option "@forceline_vcs_show_icon" "yes")}"
        max_len="${3:-$(get_tmux_option "@forceline_vcs_branch_max_len" "20")}"
        truncate_symbol="${4:-$(get_tmux_option "@forceline_vcs_truncate_symbol" "…")}"
        format="${5:-$(get_tmux_option "@forceline_vcs_format" "branch")}"

        export FORCELINE_VCS_SHOW_SYMBOL="$show_icon"
        export FORCELINE_VCS_BRANCH_MAX_LEN="$max_len"
        export FORCELINE_VCS_TRUNCATE_SYMBOL="$truncate_symbol"

        vcs_status=$(get_vcs_status_with_icon "$show_icon" "$working_dir") || exit 0

        branch_part=$(echo "$vcs_status" | cut -d: -f1)
        status_part=$(echo "$vcs_status" | cut -d: -f2-6)
        vcs_type=$(echo "$vcs_status" | cut -d: -f7)

        case "$format" in
            "branch") echo "$branch_part" ;;
            "status") echo "$status_part" ;;
            "type")   echo "$vcs_type" ;;
            "full")   echo "$vcs_status" ;;
            *)        echo "$branch_part" ;;
        esac
        ;;
    status)
        working_dir="${1:-}"
        if [[ -z "$working_dir" ]]; then
            working_dir="$(tmux display-message -p '#{pane_current_path}' 2>/dev/null || pwd)"
        fi
        format="${2:-counts}"
        show_symbols="${3:-$(get_tmux_option "@forceline_vcs_show_symbols" "yes")}"
        show_zero="${4:-$(get_tmux_option "@forceline_vcs_show_zero" "no")}"

        vcs_status=$(get_vcs_status_with_icon "no" "$working_dir") || exit 0
        status_data=$(echo "$vcs_status" | cut -d: -f2-6)

        case "$format" in
            "counts") format_status_counts "$status_data" "$show_symbols" "$show_zero" ;;
            "raw")    echo "$status_data" ;;
            *)        format_status_counts "$status_data" "$show_symbols" "$show_zero" ;;
        esac
        ;;
    color)
        color_type="${1:-bg}"; shift || true
        working_dir="${1:-}"
        if [[ -z "$working_dir" ]]; then
            working_dir="$(tmux display-message -p '#{pane_current_path}' 2>/dev/null || pwd)"
        fi

        vcs_status=$(get_vcs_status_with_icon "no" "$working_dir")
        if [ $? -ne 0 ] || [ -z "$vcs_status" ]; then
            if [ "$color_type" = "fg" ]; then echo "#{@fg}"; else echo "#{@surface_0}"; fi
            exit 0
        fi

        status_data=$(echo "$vcs_status" | cut -d: -f2-6)

        get_vcs_color "$color_type" "$status_data" \
            "$(get_tmux_option "@forceline_vcs_clean_fg" "#{@fg}")" \
            "$(get_tmux_option "@forceline_vcs_clean_bg" "#{@success}")" \
            "$(get_tmux_option "@forceline_vcs_staged_fg" "#{@base00}")" \
            "$(get_tmux_option "@forceline_vcs_staged_bg" "#{@info}")" \
            "$(get_tmux_option "@forceline_vcs_diverged_fg" "#{@base00}")" \
            "$(get_tmux_option "@forceline_vcs_diverged_bg" "#{@warning}")" \
            "$(get_tmux_option "@forceline_vcs_dirty_fg" "#{@base00}")" \
            "$(get_tmux_option "@forceline_vcs_dirty_bg" "#{@error}")"
        ;;
    *)
        echo "Usage: main.sh {branch|status|color|init} [args...]" >&2
        exit 1
        ;;
esac
