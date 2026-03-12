#!/usr/bin/env bash
# Total memory in human-readable format for tmux-forceline

case "$(uname -s)" in
    "Linux")
        if command -v free >/dev/null 2>&1; then
            memory_total=$(free -h | awk '/Mem/ {print $2}')
        else
            memory_total="N/A"
        fi
        ;;
    "Darwin")
        if command -v sysctl >/dev/null 2>&1; then
            total_bytes=$(sysctl -n hw.memsize)
            total_mb=$((total_bytes / 1024 / 1024))
            if [ $total_mb -gt 1024 ]; then
                memory_total=$(echo "scale=1; $total_mb / 1024" | bc 2>/dev/null || echo "$((total_mb / 1024))")G
            else
                memory_total="${total_mb}M"
            fi
        else
            memory_total="N/A"
        fi
        ;;
    *)
        memory_total="N/A"
        ;;
esac

echo "$memory_total"