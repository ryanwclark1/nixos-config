#!/usr/bin/env bash
# Pure cava functions for tmux-forceline
# Source this file — not meant to be executed directly

if [[ -z "${FL_VERSION:-}" ]]; then
    source "${FORCELINE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." >/dev/null && pwd)}/utils/pure_helpers.sh"
fi

# --- Configuration variables (set defaults; callers may override before sourcing or after) ---
# These are intentionally not readonly so main.sh can set them from tmux options first.
BARS="${FORCELINE_CAVA_BARS:-16}"
COLOR_MODE="${FORCELINE_CAVA_COLOR:-none}"
CACHE_TTL="${FORCELINE_CAVA_TTL:-1}"
SYMBOLS="${FORCELINE_CAVA_SYMBOLS:-▁▂▃▄▅▆▇█}"
PALETTE="${FORCELINE_CAVA_PALETTE:-24,27,33,40,76,178,208,196}"
FALLBACK="♪♫♪♫♪♫♪♫"

# Resolve 'auto' color mode
_cava_resolve_color_mode() {
    if [[ "$COLOR_MODE" == "auto" ]]; then
        if [[ -n "${TMUX:-}" ]]; then
            COLOR_MODE="tmux"
        elif command_exists tput && [[ "$(tput colors 2>/dev/null)" -ge 256 ]]; then
            COLOR_MODE="ansi"
        else
            COLOR_MODE="none"
        fi
    fi
}

# Derive computed values from configuration
_cava_init_computed() {
    _cava_resolve_color_mode
    CAVA_CACHE_DIR=$(get_module_cache_dir "cava")
    CAVA_CACHE_FILE="$CAVA_CACHE_DIR/output.cache"
    CAVA_CONFIG_FILE="/tmp/cava_forceline_cfg_$$"
    NUM_SYMBOLS=${#SYMBOLS}
    MAX_RANGE=$((NUM_SYMBOLS - 1))
}

# Write cava config file
write_cava_config() {
    cat > "$CAVA_CONFIG_FILE" <<EOF
[general]
bars = $BARS

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = $MAX_RANGE
EOF
}

# Build the awk rendering program
build_awk_program() {
    local awk_prog='BEGIN { FS=";" }'

    awk_prog+=' { out=""; for(i=1; i<=NF; i++) { v=int($i); '
    awk_prog+="if(v<0) v=0; if(v>$MAX_RANGE) v=$MAX_RANGE; "

    case "$COLOR_MODE" in
        tmux)
            IFS=',' read -ra colors <<< "$PALETTE"
            local n_colors=${#colors[@]}
            awk_prog+='ci=int(v*'"$n_colors"'/'"$((MAX_RANGE+1))"'); '
            local color_cases=""
            for ((j=0; j<n_colors; j++)); do
                color_cases+="if(ci==$j) c=\"#[fg=colour${colors[$j]}]\"; "
            done
            awk_prog+="$color_cases"
            awk_prog+='out=out c; '
            ;;
        ansi)
            IFS=',' read -ra colors <<< "$PALETTE"
            local n_colors=${#colors[@]}
            awk_prog+='ci=int(v*'"$n_colors"'/'"$((MAX_RANGE+1))"'); '
            local color_cases=""
            for ((j=0; j<n_colors; j++)); do
                color_cases+="if(ci==$j) c=\"\033[38;5;${colors[$j]}m\"; "
            done
            awk_prog+="$color_cases"
            awk_prog+='out=out c; '
            ;;
    esac

    local sym_cases=""
    for ((j=0; j<=MAX_RANGE; j++)); do
        sym_cases+="if(v==$j) s=\"${SYMBOLS:$j:1}\"; "
    done
    awk_prog+="$sym_cases"
    awk_prog+='out=out s; '
    awk_prog+='} '

    case "$COLOR_MODE" in
        tmux) awk_prog+='out=out "#[default]"; ' ;;
        ansi) awk_prog+='out=out "\033[0m"; ' ;;
    esac

    awk_prog+='print out; fflush(); }'
    echo "$awk_prog"
}

# Streaming mode — continuous output
stream_output() {
    if ! command_exists cava; then
        echo "$FALLBACK"
        return 1
    fi
    write_cava_config
    local awk_prog
    awk_prog=$(build_awk_program)
    cava -p "$CAVA_CONFIG_FILE" 2>/dev/null | awk "$awk_prog"
}

# Capture a single frame
capture_frame() {
    if ! command_exists cava; then
        return 1
    fi
    write_cava_config
    local awk_prog raw
    awk_prog=$(build_awk_program)
    raw=$(timeout 2s cava -p "$CAVA_CONFIG_FILE" 2>/dev/null | head -n 1) || true
    if [[ -n "$raw" ]]; then
        echo "$raw" | awk "$awk_prog"
    fi
}

# Return cached output, refreshing if stale
cached_output() {
    if is_cache_valid "$CAVA_CACHE_FILE" "$CACHE_TTL"; then
        cat "$CAVA_CACHE_FILE" 2>/dev/null
        return 0
    fi

    local frame
    frame=$(capture_frame)

    if [[ -n "$frame" ]]; then
        echo "$frame" | tee "$CAVA_CACHE_FILE" 2>/dev/null
    else
        echo "$FALLBACK" | tee "$CAVA_CACHE_FILE" 2>/dev/null
    fi
}

# Self-test
run_test() {
    echo "=== cava module self-test ==="
    echo "cava available: $(command_exists cava && echo "yes" || echo "NO")"
    echo "bars: $BARS  symbols: $SYMBOLS  color: $COLOR_MODE  ttl: ${CACHE_TTL}s"
    echo ""

    if ! command_exists cava; then
        echo "SKIP: cava not installed"
        return 1
    fi

    echo -n "Capturing frame... "
    local frame
    frame=$(capture_frame)
    if [[ -n "$frame" ]]; then
        echo "OK"
        echo "Output: $frame"
    else
        echo "FAIL (no output — is audio playing?)"
        echo "Fallback: $FALLBACK"
    fi
}

# Cleanup helper (call from trap in main.sh)
cava_cleanup() {
    kill %% 2>/dev/null || true
    rm -f "${CAVA_CONFIG_FILE:-}" 2>/dev/null || true
}
