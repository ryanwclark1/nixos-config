#!/usr/bin/env bash
set -euo pipefail

source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/common.sh"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
source "$CURRENT_DIR/functions.sh"

# Read tmux options (only called when no positional overrides given)
read_tmux_opts() {
    DT_DATE_FMT="$(get_tmux_option "@forceline_datetime_date_format" "%Y-%m-%d")"
    DT_TIME_FMT="$(get_tmux_option "@forceline_datetime_time_format" "%H:%M")"
    DT_TZ="$(get_tmux_option "@forceline_datetime_timezone" "")"
    DT_SEP="$(get_tmux_option "@forceline_datetime_separator" " ")"
}

# Resolve format+tz from args or tmux options
# Usage: resolve_opts <tmux_fmt_var> <default_fmt> "$@"
resolve_opts() {
    local tmux_var="$1" default_fmt="$2"
    local arg_fmt="${3:-}" arg_tz="${4:-}"
    if [[ -n "$arg_fmt" ]]; then
        R_FMT="$arg_fmt"; R_TZ="$arg_tz"
    else
        read_tmux_opts
        R_FMT="${!tmux_var:-$default_fmt}"; R_TZ="${arg_tz:-$DT_TZ}"
    fi
}

cmd="${1:-combined}"; shift || true

case "$cmd" in
    date)
        resolve_opts DT_DATE_FMT "%Y-%m-%d" "$@"
        get_date "$R_FMT" "$R_TZ"
        ;;
    time)
        resolve_opts DT_TIME_FMT "%H:%M" "$@"
        get_time "$R_FMT" "$R_TZ"
        ;;
    day)
        fmt="${1:-%A}"; tz="${2:-}"
        if [[ -z "$tz" ]]; then read_tmux_opts; tz="$DT_TZ"; fi
        get_day_of_week "$fmt" "$tz"
        ;;
    utc)
        get_utc_time "${1:-%H:%M}"
        ;;
    combined)
        date_fmt="${1:-}"; time_fmt="${2:-}"; sep="${3:-}"; tz="${4:-}"
        if [[ -z "$date_fmt" ]]; then
            read_tmux_opts
            date_fmt="$DT_DATE_FMT"; time_fmt="${time_fmt:-$DT_TIME_FMT}"
            sep="${sep:-$DT_SEP}"; tz="${tz:-$DT_TZ}"
        fi
        get_combined "$date_fmt" "${time_fmt:-%H:%M}" "${sep:- }" "$tz"
        ;;
    *)
        echo "Usage: main.sh {date|time|day|utc|combined} [args...]" >&2
        exit 1
        ;;
esac
