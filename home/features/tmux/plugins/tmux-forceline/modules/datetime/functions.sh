#!/usr/bin/env bash
# Pure datetime functions for tmux-forceline
# Source this file — not meant to be executed directly

# Internal: run date with optional TZ
_run_date() {
    local fmt="$1" tz="$2"
    if [[ -n "$tz" ]]; then
        TZ="$tz" date +"$fmt" 2>/dev/null || date +"$fmt"
    else
        date +"$fmt"
    fi
}

get_date() {
    local fmt="${1:-%Y-%m-%d}"
    local tz="${2:-}"
    _run_date "$fmt" "$tz"
}

get_time() {
    local fmt="${1:-%H:%M}"
    local tz="${2:-}"
    _run_date "$fmt" "$tz"
}

get_day_of_week() {
    local fmt="${1:-%A}"
    local tz="${2:-}"
    _run_date "$fmt" "$tz"
}

get_utc_time() {
    local fmt="${1:-%H:%M}"
    _run_date "$fmt" "UTC"
}

get_combined() {
    local date_fmt="${1:-%Y-%m-%d}"
    local time_fmt="${2:-%H:%M}"
    local sep="${3:- }"
    local tz="${4:-}"
    # Single date call with both formats joined by a sentinel, then replace it
    local combined
    combined="$(_run_date "${date_fmt}${sep}${time_fmt}" "$tz")"
    echo "$combined"
}
