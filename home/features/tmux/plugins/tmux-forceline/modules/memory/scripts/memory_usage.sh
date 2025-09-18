#!/usr/bin/env bash
# Memory usage in human-readable format for tmux-forceline

case "$(uname -s)" in
    "Linux")
        if command -v free >/dev/null 2>&1; then
            memory_usage=$(free -h | awk '/Mem/ {print $3}')
        else
            memory_usage="N/A"
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
                    used_mb = used_pages * 4096 / 1024 / 1024;
                    if (used_mb > 1024) {
                        printf "%.1fG", used_mb / 1024;
                    } else {
                        printf "%.0fM", used_mb;
                    }
                }'
            )
        else
            memory_usage="N/A"
        fi
        ;;
    *)
        memory_usage="N/A"
        ;;
esac

echo "$memory_usage"