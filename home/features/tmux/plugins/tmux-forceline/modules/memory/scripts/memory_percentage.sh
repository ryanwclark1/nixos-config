#!/usr/bin/env bash
# Memory percentage calculation for tmux-forceline

case "$(uname -s)" in
    "Linux")
        if command -v free >/dev/null 2>&1; then
            memory_percent=$(free | awk '/Mem/ {printf "%.0f", $3/$2 * 100}')
        else
            memory_percent="N/A"
        fi
        ;;
    "Darwin")
        if command -v vm_stat >/dev/null 2>&1; then
            memory_usage=$(vm_stat | awk '
                /Pages active/ { active = $3 }
                /Pages inactive/ { inactive = $3 }
                /Pages speculative/ { speculative = $3 }
                /Pages wired down/ { wired = $4 }
                /Pages occupied by compressor/ { compressed = $5 }
                END {
                    gsub(/[^0-9]/, "", active);
                    gsub(/[^0-9]/, "", inactive);
                    gsub(/[^0-9]/, "", speculative);
                    gsub(/[^0-9]/, "", wired);
                    gsub(/[^0-9]/, "", compressed);
                    used_pages = active + inactive + speculative + wired + compressed;
                    used_bytes = used_pages * 4096;
                    printf "%.0f", used_bytes / 1024 / 1024;
                }'
            )
            total_memory=$(($(sysctl -n hw.memsize) / 1024 / 1024))
            memory_percent=$((memory_usage * 100 / total_memory))
        else
            memory_percent="N/A"
        fi
        ;;
    *)
        memory_percent="N/A"
        ;;
esac

echo "${memory_percent}%"