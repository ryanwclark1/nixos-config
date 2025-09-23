#!/usr/bin/env bash
# Performance Baseline Measurement for tmux-forceline v3.0
# Establishes current performance metrics before Tao of Tmux improvements

set -euo pipefail

# Global configuration
readonly SCRIPT_VERSION="3.0"
readonly BENCHMARK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly RESULTS_DIR="$BENCHMARK_DIR/results"
readonly BASELINE_FILE="$RESULTS_DIR/baseline_$(date +%Y%m%d_%H%M%S).json"

# Source centralized utilities
UTILS_DIR="$(cd "$BENCHMARK_DIR/../utils" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
else
    echo "Error: Cannot find common.sh utilities" >&2
    exit 1
fi

# Ensure results directory exists
mkdir -p "$RESULTS_DIR"

# Benchmark configuration
readonly WARMUP_ITERATIONS=3
readonly MEASUREMENT_ITERATIONS=10
readonly TIMEOUT_SECONDS=30

# Initialize results object
init_results() {
    cat > "$BASELINE_FILE" <<EOF
{
  "metadata": {
    "timestamp": "$(date -Iseconds)",
    "version": "$SCRIPT_VERSION",
    "platform": "$(uname -s)",
    "arch": "$(uname -m)",
    "tmux_version": "$(tmux -V)",
    "shell": "$SHELL",
    "hostname": "$(hostname)"
  },
  "system_info": {},
  "module_performance": {},
  "overall_metrics": {}
}
EOF
}

# Measure system information
measure_system_info() {
    local cpu_cores memory_total load_avg
    
    cpu_cores=$(nproc 2>/dev/null || echo "unknown")
    memory_total=$(free -m 2>/dev/null | awk 'NR==2{print $2}' || echo "unknown")
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    
    # Update JSON with system info
    jq --arg cores "$cpu_cores" \
       --arg memory "$memory_total" \
       --arg load "$load_avg" \
       '.system_info = {
         "cpu_cores": $cores,
         "memory_total_mb": $memory,
         "load_average": $load
       }' "$BASELINE_FILE" > "${BASELINE_FILE}.tmp" && mv "${BASELINE_FILE}.tmp" "$BASELINE_FILE"
}

# Measure execution time of a command
measure_execution_time() {
    local command="$1"
    local iterations="$2"
    local times=()
    
    echo "Measuring: $command" >&2
    
    # Warmup iterations
    for ((i = 0; i < WARMUP_ITERATIONS; i++)); do
        timeout "$TIMEOUT_SECONDS" bash -c "$command" >/dev/null 2>&1 || true
    done
    
    # Measurement iterations
    for ((i = 0; i < iterations; i++)); do
        local start_time end_time duration
        start_time=$(date +%s.%N)
        
        if timeout "$TIMEOUT_SECONDS" bash -c "$command" >/dev/null 2>&1; then
            end_time=$(date +%s.%N)
            duration=$(echo "$end_time - $start_time" | bc -l)
            times+=("$duration")
        else
            times+=("timeout")
        fi
    done
    
    # Calculate statistics
    local valid_times=()
    for time in "${times[@]}"; do
        [[ "$time" != "timeout" ]] && valid_times+=("$time")
    done
    
    if [[ ${#valid_times[@]} -gt 0 ]]; then
        local min max avg median
        min=$(printf '%s\n' "${valid_times[@]}" | sort -n | head -1)
        max=$(printf '%s\n' "${valid_times[@]}" | sort -n | tail -1)
        avg=$(printf '%s\n' "${valid_times[@]}" | awk '{sum+=$1} END {print sum/NR}')
        median=$(printf '%s\n' "${valid_times[@]}" | sort -n | awk '{a[NR]=$1} END{print (NR%2==1)?a[int(NR/2)+1]:(a[NR/2]+a[NR/2+1])/2}')
        
        echo "{\"min\": $min, \"max\": $max, \"avg\": $avg, \"median\": $median, \"samples\": ${#valid_times[@]}, \"timeouts\": $((${#times[@]} - ${#valid_times[@]}))}"
    else
        echo "{\"min\": null, \"max\": null, \"avg\": null, \"median\": null, \"samples\": 0, \"timeouts\": ${#times[@]}}"
    fi
}

# Benchmark individual modules
benchmark_modules() {
    local modules_dir="$(get_forceline_dir)/modules"
    local module_results="{}"
    
    echo "Benchmarking individual modules..." >&2
    
    # Core modules to benchmark
    local core_modules=(
        "cpu/scripts/cpu_percentage.sh"
        "memory/scripts/memory_percentage.sh"
        "battery/scripts/battery_percentage.sh"
        "datetime/scripts/date.sh"
        "datetime/scripts/time.sh"
        "hostname/scripts/hostname.sh"
    )
    
    # Extended modules to benchmark
    local extended_modules=(
        "wan_ip/scripts/wan_ip.sh"
        "lan_ip/scripts/lan_ip.sh"
        "weather/scripts/weather.sh"
        "disk_usage/scripts/disk_usage.sh"
        "load/scripts/load_average.sh"
    )
    
    # Benchmark core modules
    for module in "${core_modules[@]}"; do
        local module_path="$modules_dir/$module"
        if [[ -f "$module_path" ]]; then
            local module_name="${module//\//_}"
            module_name="${module_name%.sh}"
            
            echo "  Benchmarking $module_name..." >&2
            local timing_result
            timing_result=$(measure_execution_time "$module_path" "$MEASUREMENT_ITERATIONS")
            
            module_results=$(echo "$module_results" | jq --arg name "$module_name" --argjson timing "$timing_result" \
                '.[$name] = $timing')
        fi
    done
    
    # Benchmark extended modules (fewer iterations due to potential network calls)
    for module in "${extended_modules[@]}"; do
        local module_path="$modules_dir/$module"
        if [[ -f "$module_path" ]]; then
            local module_name="${module//\//_}"
            module_name="${module_name%.sh}"
            
            echo "  Benchmarking $module_name (extended)..." >&2
            local timing_result
            timing_result=$(measure_execution_time "$module_path" 3)  # Fewer iterations for network modules
            
            module_results=$(echo "$module_results" | jq --arg name "$module_name" --argjson timing "$timing_result" \
                '.[$name] = $timing')
        fi
    done
    
    # Update JSON with module results
    jq --argjson modules "$module_results" \
       '.module_performance = $modules' "$BASELINE_FILE" > "${BASELINE_FILE}.tmp" && mv "${BASELINE_FILE}.tmp" "$BASELINE_FILE"
}

# Benchmark overall status bar performance
benchmark_status_bar() {
    echo "Benchmarking overall status bar performance..." >&2
    
    # Test with different status bar configurations
    local configs=(
        "minimal:#{session_name} #{window_index}:#{pane_index}"
        "basic:#{session_name} | #{window_index}:#{pane_index} | %H:%M"
        "full:#(${modules_dir}/cpu/scripts/cpu_percentage.sh) | #(${modules_dir}/memory/scripts/memory_percentage.sh) | %H:%M:%S"
    )
    
    local status_results="{}"
    local modules_dir="$(get_forceline_dir)/modules"
    
    for config in "${configs[@]}"; do
        local config_name="${config%%:*}"
        local config_value="${config#*:}"
        
        echo "  Testing $config_name configuration..." >&2
        
        # Set the status bar configuration
        tmux set-option -g status-right "$config_value"
        
        # Measure tmux refresh time
        local refresh_timing
        refresh_timing=$(measure_execution_time "tmux refresh-client" 5)
        
        status_results=$(echo "$status_results" | jq --arg name "$config_name" --argjson timing "$refresh_timing" \
            '.[$name] = $timing')
    done
    
    # Update JSON with status bar results
    jq --argjson status "$status_results" \
       '.overall_metrics.status_bar_performance = $status' "$BASELINE_FILE" > "${BASELINE_FILE}.tmp" && mv "${BASELINE_FILE}.tmp" "$BASELINE_FILE"
}

# Benchmark cache performance
benchmark_cache() {
    echo "Benchmarking cache performance..." >&2
    
    local cache_dir="${TMUX_TMPDIR:-${TMPDIR:-/tmp}}/tmux-forceline"
    mkdir -p "$cache_dir"
    
    local cache_results="{}"
    local test_data="benchmark_test_data_$(date +%s)"
    
    # Test cache write performance
    echo "  Testing cache write performance..." >&2
    local write_timing
    write_timing=$(measure_execution_time "echo '$test_data' > '$cache_dir/benchmark_test.cache'" 10)
    
    # Test cache read performance
    echo "  Testing cache read performance..." >&2
    local read_timing
    read_timing=$(measure_execution_time "cat '$cache_dir/benchmark_test.cache'" 10)
    
    # Test cache cleanup
    rm -f "$cache_dir/benchmark_test.cache"
    
    cache_results=$(echo '{}' | jq --argjson write "$write_timing" --argjson read "$read_timing" \
        '.write = $write | .read = $read')
    
    # Update JSON with cache results
    jq --argjson cache "$cache_results" \
       '.overall_metrics.cache_performance = $cache' "$BASELINE_FILE" > "${BASELINE_FILE}.tmp" && mv "${BASELINE_FILE}.tmp" "$BASELINE_FILE"
}

# Benchmark resource utilization
benchmark_resource_usage() {
    echo "Benchmarking resource utilization..." >&2
    
    local pid=$$
    local initial_memory final_memory peak_memory
    
    # Measure initial memory
    initial_memory=$(ps -o rss= -p "$pid" 2>/dev/null || echo "0")
    
    # Run intensive operations
    for ((i = 0; i < 10; i++)); do
        $(get_forceline_dir)/modules/cpu/scripts/cpu_percentage.sh >/dev/null 2>&1 || true
        $(get_forceline_dir)/modules/memory/scripts/memory_percentage.sh >/dev/null 2>&1 || true
    done
    
    # Measure peak memory
    peak_memory=$(ps -o rss= -p "$pid" 2>/dev/null || echo "0")
    
    # Wait a moment for cleanup
    sleep 2
    
    # Measure final memory
    final_memory=$(ps -o rss= -p "$pid" 2>/dev/null || echo "0")
    
    local resource_results
    resource_results=$(echo '{}' | jq --arg initial "$initial_memory" --arg peak "$peak_memory" --arg final "$final_memory" \
        '.memory_kb = {
           "initial": ($initial | tonumber),
           "peak": ($peak | tonumber),
           "final": ($final | tonumber),
           "delta": (($final | tonumber) - ($initial | tonumber))
         }')
    
    # Update JSON with resource results
    jq --argjson resources "$resource_results" \
       '.overall_metrics.resource_usage = $resources' "$BASELINE_FILE" > "${BASELINE_FILE}.tmp" && mv "${BASELINE_FILE}.tmp" "$BASELINE_FILE"
}

# Generate summary report
generate_summary() {
    echo "Generating summary report..." >&2
    
    local summary_file="${RESULTS_DIR}/baseline_summary_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$summary_file" <<EOF
# tmux-forceline Performance Baseline Report
Generated: $(date)
Version: $SCRIPT_VERSION

## System Information
$(jq -r '.system_info | to_entries | map("\(.key): \(.value)") | join("\n")' "$BASELINE_FILE")

## Module Performance Summary (Average Execution Time)
$(jq -r '.module_performance | to_entries | map("\(.key): \(.value.avg // "N/A")s") | sort | join("\n")' "$BASELINE_FILE")

## Overall Metrics
Status Bar Performance:
$(jq -r '.overall_metrics.status_bar_performance | to_entries | map("  \(.key): \(.value.avg // "N/A")s") | join("\n")' "$BASELINE_FILE")

Cache Performance:
$(jq -r '.overall_metrics.cache_performance | to_entries | map("  \(.key): \(.value.avg // "N/A")s") | join("\n")' "$BASELINE_FILE")

Resource Usage:
$(jq -r '.overall_metrics.resource_usage.memory_kb | to_entries | map("  \(.key): \(.value)KB") | join("\n")' "$BASELINE_FILE")

## Performance Targets for Improvement
Based on Tao of Tmux principles, target improvements:
- Module execution time: 60-80% reduction
- Status bar update latency: <100ms
- Memory usage: <10MB total
- Cache hit rate: >85%

## Baseline Data Location
Raw data: $BASELINE_FILE
Summary: $summary_file
EOF
    
    echo "Summary report generated: $summary_file" >&2
    echo "Raw baseline data: $BASELINE_FILE" >&2
}

# Main execution
main() {
    echo "Starting tmux-forceline performance baseline measurement..." >&2
    echo "This may take several minutes..." >&2
    
    # Check dependencies
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required for JSON processing" >&2
        exit 1
    fi
    
    if ! command -v bc >/dev/null 2>&1; then
        echo "Error: bc is required for calculations" >&2
        exit 1
    fi
    
    # Initialize results
    init_results
    
    # Run benchmark suite
    measure_system_info
    benchmark_modules
    benchmark_status_bar
    benchmark_cache
    benchmark_resource_usage
    
    # Generate summary
    generate_summary
    
    echo "Baseline measurement complete!" >&2
    echo "Results saved to: $BASELINE_FILE" >&2
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi