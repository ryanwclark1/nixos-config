#!/usr/bin/env bash
# Pure CPU functions for tmux-forceline
# Source this file — not meant to be executed directly

# Guard: skip if already loaded via source_helpers.sh (which includes common.sh)
if [[ -z "${FL_VERSION:-}" ]]; then
    source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/pure_helpers.sh"
fi

print_cpu_percentage() {
    local cpu_percentage_format="${1:-%3.1f%%}"

    if command_exists "iostat"; then
        if is_linux_iostat; then
            cached_eval iostat -c 1 2 | sed '/^\s*$/d' | tail -n 1 | awk -v format="$cpu_percentage_format" '{usage=100-$NF} END {printf(format, usage)}' | sed 's/,/./'
        elif is_osx; then
            cached_eval iostat -c 2 disk0 | sed '/^\s*$/d' | tail -n 1 | awk -v format="$cpu_percentage_format" '{usage=100-$6} END {printf(format, usage)}' | sed 's/,/./'
        elif is_freebsd || is_openbsd; then
            cached_eval iostat -c 2 | sed '/^\s*$/d' | tail -n 1 | awk -v format="$cpu_percentage_format" '{usage=100-$NF} END {printf(format, usage)}' | sed 's/,/./'
        else
            echo "Unknown iostat version please create an issue"
        fi
    elif command_exists "sar"; then
        cached_eval sar -u 1 1 | sed '/^\s*$/d' | tail -n 1 | awk -v format="$cpu_percentage_format" '{usage=100-$NF} END {printf(format, usage)}' | sed 's/,/./'
    else
        if is_cygwin; then
            local usage
            usage="$(cached_eval WMIC cpu get LoadPercentage | grep -Eo '^[0-9]+')"
            # shellcheck disable=SC2059
            printf "$cpu_percentage_format" "$usage"
        else
            local load cpus
            load=$(cached_eval ps aux | awk '{print $3}' | tail -n+2 | awk '{s+=$1} END {print s}')
            cpus=$(cpus_number)
            echo "$load $cpus" | awk -v format="$cpu_percentage_format" '{printf format, $1/$2}'
        fi
    fi
}

print_cpu_temp() {
    local cpu_temp_format="${1:-%2.0f}"
    local cpu_temp_unit="${2:-C}"

    if command_exists "sensors"; then
        local val
        if [[ "$cpu_temp_unit" == F ]]; then
            val="$(sensors -f)"
        else
            val="$(sensors)"
        fi
        echo "$val" | sed -e 's/^Tccd/Core /' | awk -v format="$cpu_temp_format$cpu_temp_unit" '/^Core [0-9]+/ {gsub("[^0-9.]", "", $3); sum+=$3; n+=1} END {printf(format, sum/n)}'
    fi
}
