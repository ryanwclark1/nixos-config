#!/usr/bin/env bash
# Performance Benchmarking Tool for tmux-forceline v3.0
# Comprehensive testing of native vs hybrid vs traditional shell approaches
# Validates the performance improvements claimed in the Tao of Tmux implementation

set -euo pipefail

# Source centralized utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
else
    # Fallback tmux option functions
    get_tmux_option() {
        local option="$1"
        local default="$2"
        tmux show-option -gqv "$option" 2>/dev/null || echo "$default"
    }
    
    set_tmux_option() {
        local option="$1"
        local value="$2"
        tmux set-option -gq "$option" "$value"
    }
fi

# Benchmark configuration
declare -A BENCHMARK_CONFIG=(
    ["iterations"]="100"
    ["warmup_iterations"]="10"
    ["timeout_seconds"]="30"
    ["output_format"]="table"  # table, json, csv
    ["log_level"]="info"       # debug, info, warn, error
    ["save_results"]="yes"
    ["compare_modes"]="yes"
)

# Module categories for testing
declare -A MODULE_CATEGORIES=(
    ["native"]="session hostname datetime"
    ["hybrid"]="directory load uptime"
    ["enhanced_shell"]="cpu memory battery"
    ["network"]="wan_ip lan_ip"
)

# Benchmark results storage
declare -A BENCHMARK_RESULTS=()
declare -a BENCHMARK_LOG=()

# Performance tracking
BENCHMARK_START_TIME=""
BENCHMARK_TOTAL_TESTS=0
BENCHMARK_PASSED_TESTS=0
BENCHMARK_FAILED_TESTS=0

# Utility functions
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%H:%M:%S.%3N')
    
    if [[ "${BENCHMARK_CONFIG[log_level]}" == "debug" ]] || 
       [[ "$level" != "debug" && "${BENCHMARK_CONFIG[log_level]}" == "info" ]] ||
       [[ "$level" =~ ^(warn|error)$ ]]; then
        echo "[$timestamp] [$level] $message" >&2
        BENCHMARK_LOG+=("$timestamp|$level|$message")
    fi
}

# High-precision timing function
get_precise_time() {
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import time; print(time.time())"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        date +%s.%N
    else
        # Fallback for macOS/BSD
        date +%s
    fi
}

# Calculate time difference in milliseconds
calc_time_diff() {
    local start="$1"
    local end="$2"
    
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "print(f'{($end - $start) * 1000:.3f}')" <<< "$start $end"
    else
        # Bash arithmetic fallback (less precise)
        local diff_ms=$(echo "($end - $start) * 1000" | bc -l 2>/dev/null || echo "0")
        printf "%.3f" "$diff_ms"
    fi
}

# Test native tmux format performance
benchmark_native_format() {
    local format_string="$1"
    local test_name="$2"
    local iterations="${3:-${BENCHMARK_CONFIG[iterations]}}"
    
    log_message "debug" "Testing native format: $test_name"
    
    local total_time=0
    local successful_runs=0
    
    # Warmup
    for ((i=1; i<=${BENCHMARK_CONFIG[warmup_iterations]}; i++)); do
        tmux display-message -p "$format_string" >/dev/null 2>&1 || true
    done
    
    # Actual benchmark
    for ((i=1; i<=iterations; i++)); do
        local start_time=$(get_precise_time)
        
        if tmux display-message -p "$format_string" >/dev/null 2>&1; then
            local end_time=$(get_precise_time)
            local run_time=$(calc_time_diff "$start_time" "$end_time")
            total_time=$(echo "$total_time + $run_time" | bc -l 2>/dev/null || echo "$total_time")
            ((successful_runs++))
        fi
    done
    
    if [[ $successful_runs -gt 0 ]]; then
        local avg_time=$(echo "scale=3; $total_time / $successful_runs" | bc -l 2>/dev/null || echo "0")
        BENCHMARK_RESULTS["native_${test_name}_avg_ms"]="$avg_time"
        BENCHMARK_RESULTS["native_${test_name}_total_ms"]="$total_time"
        BENCHMARK_RESULTS["native_${test_name}_success_rate"]=$(echo "scale=2; $successful_runs * 100 / $iterations" | bc -l 2>/dev/null || echo "0")
        
        log_message "info" "Native $test_name: ${avg_time}ms avg (${successful_runs}/${iterations} success)"
        return 0
    else
        log_message "error" "Native $test_name: All tests failed"
        return 1
    fi
}

# Test shell command performance
benchmark_shell_command() {
    local command="$1"
    local test_name="$2"
    local iterations="${3:-${BENCHMARK_CONFIG[iterations]}}"
    
    log_message "debug" "Testing shell command: $test_name"
    
    local total_time=0
    local successful_runs=0
    
    # Warmup
    for ((i=1; i<=${BENCHMARK_CONFIG[warmup_iterations]}; i++)); do
        eval "$command" >/dev/null 2>&1 || true
    done
    
    # Actual benchmark
    for ((i=1; i<=iterations; i++)); do
        local start_time=$(get_precise_time)
        
        if timeout "${BENCHMARK_CONFIG[timeout_seconds]}" bash -c "$command" >/dev/null 2>&1; then
            local end_time=$(get_precise_time)
            local run_time=$(calc_time_diff "$start_time" "$end_time")
            total_time=$(echo "$total_time + $run_time" | bc -l 2>/dev/null || echo "$total_time")
            ((successful_runs++))
        fi
    done
    
    if [[ $successful_runs -gt 0 ]]; then
        local avg_time=$(echo "scale=3; $total_time / $successful_runs" | bc -l 2>/dev/null || echo "0")
        BENCHMARK_RESULTS["shell_${test_name}_avg_ms"]="$avg_time"
        BENCHMARK_RESULTS["shell_${test_name}_total_ms"]="$total_time"
        BENCHMARK_RESULTS["shell_${test_name}_success_rate"]=$(echo "scale=2; $successful_runs * 100 / $iterations" | bc -l 2>/dev/null || echo "0")
        
        log_message "info" "Shell $test_name: ${avg_time}ms avg (${successful_runs}/${iterations} success)"
        return 0
    else
        log_message "error" "Shell $test_name: All tests failed"
        return 1
    fi
}

# Test hybrid format performance
benchmark_hybrid_format() {
    local script_path="$1"
    local native_format="$2"
    local test_name="$3"
    local iterations="${4:-${BENCHMARK_CONFIG[iterations]}}"
    
    log_message "debug" "Testing hybrid format: $test_name"
    
    if [[ ! -f "$script_path" ]]; then
        log_message "error" "Hybrid script not found: $script_path"
        return 1
    fi
    
    # First, populate environment variables with hybrid script
    "$script_path" >/dev/null 2>&1 || true
    
    # Then benchmark the native format access
    benchmark_native_format "$native_format" "${test_name}_display" "$iterations"
    
    # Also benchmark the hybrid script itself (for cache update cost)
    benchmark_shell_command "$script_path" "${test_name}_update" "10"  # Fewer iterations for expensive operations
}

# Core benchmark tests
run_session_benchmarks() {
    log_message "info" "Running session module benchmarks..."
    
    # Native session formats
    benchmark_native_format "#{session_name}" "session_name"
    benchmark_native_format "#{session_name}:#{window_index}.#{pane_index}" "session_full"
    benchmark_native_format "#{?session_many_attached,#[fg=red],#[fg=green]}#{session_name}#[default]" "session_colored"
    
    # Traditional shell equivalent
    benchmark_shell_command "tmux display-message -p '#{session_name}'" "session_shell_equiv"
    
    ((BENCHMARK_TOTAL_TESTS += 4))
}

run_hostname_benchmarks() {
    log_message "info" "Running hostname module benchmarks..."
    
    # Native hostname formats
    benchmark_native_format "#{host}" "hostname_full"
    benchmark_native_format "#{host_short}" "hostname_short"
    
    # Traditional shell equivalent
    benchmark_shell_command "hostname" "hostname_shell_equiv"
    benchmark_shell_command "hostname -s" "hostname_short_shell_equiv"
    
    ((BENCHMARK_TOTAL_TESTS += 4))
}

run_datetime_benchmarks() {
    log_message "info" "Running datetime module benchmarks..."
    
    # Native datetime formats
    benchmark_native_format "#{T:%H:%M:%S}" "datetime_time"
    benchmark_native_format "#{T:%Y-%m-%d %H:%M:%S}" "datetime_full"
    benchmark_native_format "#{T:%a %b %d}" "datetime_date"
    
    # Traditional shell equivalent
    benchmark_shell_command "date '+%H:%M:%S'" "datetime_shell_time"
    benchmark_shell_command "date '+%Y-%m-%d %H:%M:%S'" "datetime_shell_full"
    
    ((BENCHMARK_TOTAL_TESTS += 5))
}

run_directory_benchmarks() {
    log_message "info" "Running directory module benchmarks..."
    
    # Native directory formats
    benchmark_native_format "#{pane_current_path}" "directory_full"
    benchmark_native_format "#{b:pane_current_path}" "directory_basename"
    benchmark_native_format "#{s|$HOME|~|:pane_current_path}" "directory_home_relative"
    
    # Hybrid directory format (if available)
    local hybrid_script="$(dirname "$UTILS_DIR")/modules/directory/directory_hybrid.sh"
    if [[ -f "$hybrid_script" ]]; then
        benchmark_hybrid_format "$hybrid_script" "#{E:FORCELINE_DIRECTORY_FORMATTED}" "directory_hybrid"
    fi
    
    # Traditional shell equivalent
    benchmark_shell_command "pwd" "directory_shell_full"
    benchmark_shell_command "basename \$(pwd)" "directory_shell_basename"
    
    ((BENCHMARK_TOTAL_TESTS += 6))
}

run_load_benchmarks() {
    log_message "info" "Running load module benchmarks..."
    
    # Hybrid load format (if available)
    local hybrid_script="$(dirname "$UTILS_DIR")/modules/load/load_hybrid.sh"
    if [[ -f "$hybrid_script" ]]; then
        benchmark_hybrid_format "$hybrid_script" "#{E:FORCELINE_LOAD_CURRENT}" "load_hybrid"
    fi
    
    # Traditional shell equivalent
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        benchmark_shell_command "cat /proc/loadavg | awk '{print \$1}'" "load_shell_proc"
    fi
    benchmark_shell_command "uptime | awk -F'load average:' '{print \$2}' | awk '{print \$1}' | tr -d ','" "load_shell_uptime"
    
    ((BENCHMARK_TOTAL_TESTS += 3))
}

run_uptime_benchmarks() {
    log_message "info" "Running uptime module benchmarks..."
    
    # Hybrid uptime format (if available)
    local hybrid_script="$(dirname "$UTILS_DIR")/modules/uptime/uptime_hybrid.sh"
    if [[ -f "$hybrid_script" ]]; then
        benchmark_hybrid_format "$hybrid_script" "#{E:FORCELINE_UPTIME_FORMATTED}" "uptime_hybrid"
    fi
    
    # Traditional shell equivalent
    benchmark_shell_command "uptime -p 2>/dev/null || uptime" "uptime_shell"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        benchmark_shell_command "awk '{print int(\$1/3600)\"h \" int((\$1%3600)/60)\"m\"}' /proc/uptime" "uptime_shell_proc"
    fi
    
    ((BENCHMARK_TOTAL_TESTS += 3))
}

# Calculate performance improvements
calculate_improvements() {
    log_message "info" "Calculating performance improvements..."
    
    # Session improvements (native vs shell)
    if [[ -n "${BENCHMARK_RESULTS[native_session_name_avg_ms]:-}" ]] && 
       [[ -n "${BENCHMARK_RESULTS[shell_session_shell_equiv_avg_ms]:-}" ]]; then
        local native_time="${BENCHMARK_RESULTS[native_session_name_avg_ms]}"
        local shell_time="${BENCHMARK_RESULTS[shell_session_shell_equiv_avg_ms]}"
        local improvement=$(echo "scale=1; ($shell_time - $native_time) * 100 / $shell_time" | bc -l 2>/dev/null || echo "0")
        BENCHMARK_RESULTS["session_improvement_percent"]="$improvement"
    fi
    
    # Directory improvements (hybrid vs shell)
    if [[ -n "${BENCHMARK_RESULTS[native_directory_hybrid_display_avg_ms]:-}" ]] && 
       [[ -n "${BENCHMARK_RESULTS[shell_directory_shell_basename_avg_ms]:-}" ]]; then
        local hybrid_time="${BENCHMARK_RESULTS[native_directory_hybrid_display_avg_ms]}"
        local shell_time="${BENCHMARK_RESULTS[shell_directory_shell_basename_avg_ms]}"
        local improvement=$(echo "scale=1; ($shell_time - $hybrid_time) * 100 / $shell_time" | bc -l 2>/dev/null || echo "0")
        BENCHMARK_RESULTS["directory_improvement_percent"]="$improvement"
    fi
    
    # Calculate overall system improvement
    local total_native_time=0
    local total_shell_time=0
    local native_count=0
    local shell_count=0
    
    for key in "${!BENCHMARK_RESULTS[@]}"; do
        if [[ "$key" =~ native_.*_avg_ms$ ]]; then
            total_native_time=$(echo "$total_native_time + ${BENCHMARK_RESULTS[$key]}" | bc -l 2>/dev/null || echo "$total_native_time")
            ((native_count++))
        elif [[ "$key" =~ shell_.*_avg_ms$ ]]; then
            total_shell_time=$(echo "$total_shell_time + ${BENCHMARK_RESULTS[$key]}" | bc -l 2>/dev/null || echo "$total_shell_time")
            ((shell_count++))
        fi
    done
    
    if [[ $native_count -gt 0 && $shell_count -gt 0 ]]; then
        local avg_native=$(echo "scale=3; $total_native_time / $native_count" | bc -l 2>/dev/null || echo "0")
        local avg_shell=$(echo "scale=3; $total_shell_time / $shell_count" | bc -l 2>/dev/null || echo "0")
        local overall_improvement=$(echo "scale=1; ($avg_shell - $avg_native) * 100 / $avg_shell" | bc -l 2>/dev/null || echo "0")
        BENCHMARK_RESULTS["overall_improvement_percent"]="$overall_improvement"
    fi
}

# Generate benchmark report
generate_report() {
    local output_file="${1:-}"
    
    log_message "info" "Generating benchmark report..."
    
    local report_content=""
    
    # Header
    report_content+="# tmux-forceline v3.0 Performance Benchmark Report\n"
    report_content+="Generated: $(date '+%Y-%m-%d %H:%M:%S')\n"
    report_content+="System: $(uname -s) $(uname -r)\n"
    report_content+="Iterations: ${BENCHMARK_CONFIG[iterations]}\n\n"
    
    # Performance Summary
    report_content+="## Performance Summary\n\n"
    if [[ -n "${BENCHMARK_RESULTS[overall_improvement_percent]:-}" ]]; then
        report_content+="**Overall Performance Improvement**: ${BENCHMARK_RESULTS[overall_improvement_percent]}%\n\n"
    fi
    
    if [[ -n "${BENCHMARK_RESULTS[session_improvement_percent]:-}" ]]; then
        report_content+="**Session Module (Native)**: ${BENCHMARK_RESULTS[session_improvement_percent]}% improvement\n"
    fi
    
    if [[ -n "${BENCHMARK_RESULTS[directory_improvement_percent]:-}" ]]; then
        report_content+="**Directory Module (Hybrid)**: ${BENCHMARK_RESULTS[directory_improvement_percent]}% improvement\n"
    fi
    
    report_content+="\n## Detailed Results\n\n"
    
    # Generate table format
    case "${BENCHMARK_CONFIG[output_format]}" in
        "table")
            report_content+="| Module | Type | Avg Time (ms) | Success Rate (%) |\n"
            report_content+="|--------|------|---------------|------------------|\n"
            
            for key in $(printf '%s\n' "${!BENCHMARK_RESULTS[@]}" | grep '_avg_ms$' | sort); do
                local module_name=$(echo "$key" | sed 's/_avg_ms$//' | sed 's/^[^_]*_//')
                local type=$(echo "$key" | cut -d'_' -f1)
                local avg_time="${BENCHMARK_RESULTS[$key]}"
                local success_key="${key/_avg_ms/_success_rate}"
                local success_rate="${BENCHMARK_RESULTS[$success_key]:-N/A}"
                
                report_content+="| $module_name | $type | $avg_time | $success_rate |\n"
            done
            ;;
        "json")
            report_content+="```json\n"
            report_content+="{\n"
            local first=true
            for key in "${!BENCHMARK_RESULTS[@]}"; do
                if [[ "$first" == true ]]; then
                    first=false
                else
                    report_content+=",\n"
                fi
                report_content+="  \"$key\": \"${BENCHMARK_RESULTS[$key]}\""
            done
            report_content+="\n}\n```\n"
            ;;
        "csv")
            report_content+="Module,Type,AvgTime_ms,SuccessRate_percent\n"
            for key in $(printf '%s\n' "${!BENCHMARK_RESULTS[@]}" | grep '_avg_ms$' | sort); do
                local module_name=$(echo "$key" | sed 's/_avg_ms$//' | sed 's/^[^_]*_//')
                local type=$(echo "$key" | cut -d'_' -f1)
                local avg_time="${BENCHMARK_RESULTS[$key]}"
                local success_key="${key/_avg_ms/_success_rate}"
                local success_rate="${BENCHMARK_RESULTS[$success_key]:-0}"
                
                report_content+="$module_name,$type,$avg_time,$success_rate\n"
            done
            ;;
    esac
    
    # Output report
    if [[ -n "$output_file" ]]; then
        echo -e "$report_content" > "$output_file"
        log_message "info" "Report saved to: $output_file"
    else
        echo -e "$report_content"
    fi
}

# Main benchmark execution
main() {
    local output_file=""
    local run_specific=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --output|-o)
                output_file="$2"
                shift 2
                ;;
            --iterations|-i)
                BENCHMARK_CONFIG["iterations"]="$2"
                shift 2
                ;;
            --format|-f)
                BENCHMARK_CONFIG["output_format"]="$2"
                shift 2
                ;;
            --module|-m)
                run_specific="$2"
                shift 2
                ;;
            --log-level|-l)
                BENCHMARK_CONFIG["log_level"]="$2"
                shift 2
                ;;
            --help|-h)
                cat << EOF
Usage: $0 [OPTIONS]

Options:
  -o, --output FILE        Save report to file
  -i, --iterations NUM     Number of iterations (default: 100)
  -f, --format FORMAT      Output format: table, json, csv (default: table)
  -m, --module MODULE      Run specific module: session, hostname, datetime, directory, load, uptime
  -l, --log-level LEVEL    Log level: debug, info, warn, error (default: info)
  -h, --help              Show this help

Examples:
  $0                       Run all benchmarks
  $0 -m session           Run only session benchmarks
  $0 -o report.md -f table Generate table report
  $0 -i 500 -l debug      Run 500 iterations with debug logging
EOF
                exit 0
                ;;
            *)
                log_message "error" "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Validation
    if ! [[ "${BENCHMARK_CONFIG[iterations]}" =~ ^[0-9]+$ ]] || [[ "${BENCHMARK_CONFIG[iterations]}" -lt 1 ]]; then
        log_message "error" "Invalid iterations: ${BENCHMARK_CONFIG[iterations]}"
        exit 1
    fi
    
    BENCHMARK_START_TIME=$(get_precise_time)
    log_message "info" "Starting tmux-forceline performance benchmark..."
    log_message "info" "Configuration: ${BENCHMARK_CONFIG[iterations]} iterations, ${BENCHMARK_CONFIG[output_format]} format"
    
    # Check tmux availability
    if ! command -v tmux >/dev/null 2>&1; then
        log_message "error" "tmux not found - benchmarking requires tmux"
        exit 1
    fi
    
    # Ensure tmux session exists
    if ! tmux list-sessions >/dev/null 2>&1; then
        log_message "warn" "No tmux sessions found - creating temporary session for benchmarking"
        tmux new-session -d -s benchmark_session "sleep 60" || {
            log_message "error" "Failed to create tmux session for benchmarking"
            exit 1
        }
    fi
    
    # Run benchmarks
    case "$run_specific" in
        "session") run_session_benchmarks ;;
        "hostname") run_hostname_benchmarks ;;
        "datetime") run_datetime_benchmarks ;;
        "directory") run_directory_benchmarks ;;
        "load") run_load_benchmarks ;;
        "uptime") run_uptime_benchmarks ;;
        "")
            run_session_benchmarks
            run_hostname_benchmarks
            run_datetime_benchmarks
            run_directory_benchmarks
            run_load_benchmarks
            run_uptime_benchmarks
            ;;
        *)
            log_message "error" "Unknown module: $run_specific"
            exit 1
            ;;
    esac
    
    # Calculate improvements and generate report
    calculate_improvements
    
    local end_time=$(get_precise_time)
    local total_time=$(calc_time_diff "$BENCHMARK_START_TIME" "$end_time")
    
    log_message "info" "Benchmark completed in ${total_time}ms"
    log_message "info" "Tests: $BENCHMARK_TOTAL_TESTS total"
    
    # Generate report
    generate_report "$output_file"
    
    # Save results if requested
    if [[ "${BENCHMARK_CONFIG[save_results]}" == "yes" ]]; then
        local results_dir="$(dirname "$UTILS_DIR")/benchmark_results"
        mkdir -p "$results_dir"
        local timestamp=$(date '+%Y%m%d_%H%M%S')
        generate_report "$results_dir/benchmark_${timestamp}.md"
        log_message "info" "Results saved to: $results_dir/benchmark_${timestamp}.md"
    fi
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi