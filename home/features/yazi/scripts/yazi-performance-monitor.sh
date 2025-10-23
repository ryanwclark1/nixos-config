#!/usr/bin/env bash
# Yazi Performance Monitor
# Monitors Yazi performance and provides optimization suggestions

set -euo pipefail

CACHE_DIR="${HOME}/.cache/yazi"
LOG_FILE="${CACHE_DIR}/performance.log"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Function to log performance metrics
log_performance() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local metric="$1"
    local value="$2"
    echo "[$timestamp] $metric: $value" >> "$LOG_FILE"
}

# Function to check Yazi version
check_yazi_version() {
    if command -v yazi >/dev/null 2>&1; then
        local version=$(yazi --version 2>/dev/null | head -n1)
        log_performance "yazi_version" "$version"
        echo "✓ Yazi version: $version"
    else
        echo "✗ Yazi not found"
        return 1
    fi
}

# Function to check cache performance
check_cache_performance() {
    if [[ -d "$CACHE_DIR" ]]; then
        local cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
        local cache_files=$(find "$CACHE_DIR" -type f 2>/dev/null | wc -l)
        log_performance "cache_size" "$cache_size"
        log_performance "cache_files" "$cache_files"
        echo "✓ Cache size: $cache_size ($cache_files files)"

        # Suggest cache cleanup if too large
        local cache_size_bytes=$(du -sb "$CACHE_DIR" 2>/dev/null | cut -f1)
        if [[ $cache_size_bytes -gt 1073741824 ]]; then  # 1GB
            echo "⚠ Cache is large (>1GB), consider cleaning: rm -rf $CACHE_DIR/*"
        fi
    else
        echo "✗ Cache directory not found"
    fi
}

# Function to check dependencies
check_dependencies() {
    local deps=("bat" "exiftool" "imagemagick" "ueberzugpp" "jq" "tree" "fd" "ripgrep")
    local missing=()

    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            echo "✓ $dep available"
        else
            echo "✗ $dep missing"
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "⚠ Missing dependencies: ${missing[*]}"
        echo "  Install with: nix profile install nixpkgs#${missing[*]}"
    fi
}

# Function to check system resources
check_system_resources() {
    local memory=$(free -h | awk '/^Mem:/ {print $2}')
    local cpu_cores=$(nproc)
    local disk_space=$(df -h "$HOME" | awk 'NR==2 {print $4}')

    log_performance "memory" "$memory"
    log_performance "cpu_cores" "$cpu_cores"
    log_performance "disk_space" "$disk_space"

    echo "✓ System resources:"
    echo "  Memory: $memory"
    echo "  CPU cores: $cpu_cores"
    echo "  Disk space: $disk_space"
}

# Function to provide optimization suggestions
provide_suggestions() {
    echo ""
    echo "🔧 Optimization Suggestions:"
    echo ""

    # Check if suppress_preload is enabled
    if grep -q "suppress_preload = true" ~/.config/yazi/yazi.toml 2>/dev/null; then
        echo "• Consider setting suppress_preload = false for better preview performance"
    fi

    # Check image_alloc setting
    local image_alloc=$(grep "image_alloc" ~/.config/yazi/yazi.toml 2>/dev/null | grep -o '[0-9]*' || echo "unknown")
    if [[ "$image_alloc" != "unknown" ]] && [[ $image_alloc -lt 1073741824 ]]; then
        echo "• Consider increasing image_alloc to 1GB (1073741824) for better image previews"
    fi

    # Check worker settings
    local micro_workers=$(grep "micro_workers" ~/.config/yazi/yazi.toml 2>/dev/null | grep -o '[0-9]*' || echo "unknown")
    if [[ "$micro_workers" != "unknown" ]] && [[ $micro_workers -lt 20 ]]; then
        echo "• Consider increasing micro_workers to 20+ for better performance"
    fi

    echo "• Use 'T' key to maximize preview pane when needed"
    echo "• Use 'E' key to toggle directory tree view"
    echo "• Use 'g r' to quickly navigate to git root"
    echo "• Use 'g i' to open lazygit integration"
}

# Main function
main() {
    echo "🔍 Yazi Performance Monitor"
    echo "=========================="
    echo ""

    check_yazi_version
    echo ""

    check_cache_performance
    echo ""

    check_dependencies
    echo ""

    check_system_resources
    echo ""

    provide_suggestions

    echo ""
    echo "📊 Performance log: $LOG_FILE"
    echo "🔄 Run this script periodically to monitor performance"
}

# Run main function
main "$@"
