#!/usr/bin/env bash
# DateTime Helper Functions for tmux-forceline v2.0
# Cross-platform date and time utilities with timezone support

# Default configurations
DATETIME_DATE_FORMAT="${FORCELINE_DATETIME_DATE_FORMAT:-%Y-%m-%d}"
DATETIME_TIME_FORMAT="${FORCELINE_DATETIME_TIME_FORMAT:-%H:%M}"
DATETIME_TIMEZONE="${FORCELINE_DATETIME_TIMEZONE:-}"
DATETIME_LOCALE="${FORCELINE_DATETIME_LOCALE:-}"

# Get current date with specified format
get_date() {
    local format="${1:-$DATETIME_DATE_FORMAT}"
    local tz="${2:-$DATETIME_TIMEZONE}"
    
    if [ -n "$tz" ]; then
        if [ -n "$DATETIME_LOCALE" ]; then
            LC_TIME="$DATETIME_LOCALE" TZ="$tz" date +"$format" 2>/dev/null || date +"$format"
        else
            TZ="$tz" date +"$format" 2>/dev/null || date +"$format"
        fi
    else
        if [ -n "$DATETIME_LOCALE" ]; then
            LC_TIME="$DATETIME_LOCALE" date +"$format" 2>/dev/null || date +"$format"
        else
            date +"$format"
        fi
    fi
}

# Get current time with specified format
get_time() {
    local format="${1:-$DATETIME_TIME_FORMAT}"
    local tz="${2:-$DATETIME_TIMEZONE}"
    
    if [ -n "$tz" ]; then
        if [ -n "$DATETIME_LOCALE" ]; then
            LC_TIME="$DATETIME_LOCALE" TZ="$tz" date +"$format" 2>/dev/null || date +"$format"
        else
            TZ="$tz" date +"$format" 2>/dev/null || date +"$format"
        fi
    else
        if [ -n "$DATETIME_LOCALE" ]; then
            LC_TIME="$DATETIME_LOCALE" date +"$format" 2>/dev/null || date +"$format"
        else
            date +"$format"
        fi
    fi
}

# Get day of week
get_day_of_week() {
    local format="${1:-%A}"  # Full weekday name by default
    local tz="${2:-$DATETIME_TIMEZONE}"
    
    get_date "$format" "$tz"
}

# Get UTC time
get_utc_time() {
    local format="${1:-$DATETIME_TIME_FORMAT}"
    TZ="UTC" date +"$format"
}

# Get Unix timestamp
get_timestamp() {
    date +%s
}

# Check if timezone is valid
is_valid_timezone() {
    local tz="$1"
    [ -n "$tz" ] && TZ="$tz" date >/dev/null 2>&1
}