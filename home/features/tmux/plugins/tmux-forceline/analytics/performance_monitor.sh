#!/usr/bin/env bash
# tmux-forceline v3.0 Performance Monitor & Analytics
# Real-time performance monitoring with intelligent optimization recommendations

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FORCELINE_DIR="$(dirname "$SCRIPT_DIR")"
readonly ANALYTICS_DIR="${HOME}/.cache/tmux-forceline/analytics"
readonly METRICS_DB="$ANALYTICS_DIR/metrics.db"
readonly PERFORMANCE_LOG="$ANALYTICS_DIR/performance.log"
readonly OPTIMIZATION_HISTORY="$ANALYTICS_DIR/optimizations.json"
readonly REAL_TIME_STATS="$ANALYTICS_DIR/realtime.json"

# Performance thresholds
readonly EXEC_TIME_WARN=50      # milliseconds
readonly EXEC_TIME_CRITICAL=100 # milliseconds
readonly MEMORY_WARN=5          # MB
readonly MEMORY_CRITICAL=10     # MB
readonly UPDATE_RATE_WARN=10    # updates per second
readonly UPDATE_RATE_CRITICAL=20

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Function: Print colored output
print_status() {
    local level="$1"
    shift
    case "$level" in
        "info")    echo -e "${BLUE}ℹ${NC} $*" ;;
        "success") echo -e "${GREEN}✅${NC} $*" ;;
        "warning") echo -e "${YELLOW}⚠${NC} $*" ;;
        "error")   echo -e "${RED}❌${NC} $*" ;;
        "header")  echo -e "${PURPLE}📊${NC} ${WHITE}$*${NC}" ;;
        "metric")  echo -e "${CYAN}📈${NC} $*" ;;
    esac
}

# Function: Initialize analytics system
init_analytics() {
    mkdir -p "$ANALYTICS_DIR"
    
    # Initialize performance log
    if [[ ! -f "$PERFORMANCE_LOG" ]]; then
        echo "timestamp,module,operation,exec_time_ms,memory_kb,cpu_percent,status,optimization_applied" > "$PERFORMANCE_LOG"
    fi
    
    # Initialize optimization history
    if [[ ! -f "$OPTIMIZATION_HISTORY" ]]; then
        cat > "$OPTIMIZATION_HISTORY" << 'EOF'
{
  "version": "1.0",
  "optimizations": [],
  "current_config": {
    "update_interval": 1,
    "cache_ttl": 5,
    "modules_enabled": [],
    "performance_mode": "balanced"
  },
  "baseline_metrics": {},
  "last_analysis": 0
}
EOF
    fi
    
    # Initialize real-time stats
    if [[ ! -f "$REAL_TIME_STATS" ]]; then
        cat > "$REAL_TIME_STATS" << 'EOF'
{
  "current_metrics": {
    "total_exec_time": 0,
    "update_frequency": 0,
    "memory_usage": 0,
    "cpu_usage": 0,
    "module_count": 0
  },
  "performance_score": 100,
  "status": "optimal",
  "last_update": 0,
  "recommendations": []
}
EOF
    fi
}

# Function: Capture module performance metrics
capture_module_metrics() {
    local module_name="$1"
    local operation="${2:-update}"
    local start_time="$3"
    local end_time="$4"
    
    local exec_time=$((end_time - start_time))
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Get memory usage (approximate)
    local memory_usage=0
    if command -v ps >/dev/null 2>&1; then
        local tmux_pid
        tmux_pid=$(pgrep -f "tmux.*server" | head -1)
        if [[ -n "$tmux_pid" ]]; then
            memory_usage=$(ps -o rss= -p "$tmux_pid" 2>/dev/null || echo "0")
        fi
    fi
    
    # Get CPU usage (simplified)
    local cpu_usage=0
    if [[ -f "/proc/loadavg" ]]; then
        cpu_usage=$(cut -d' ' -f1 /proc/loadavg | cut -d'.' -f1)
    fi
    
    # Determine status
    local status="OK"
    if [[ $exec_time -gt $EXEC_TIME_CRITICAL ]]; then
        status="CRITICAL"
    elif [[ $exec_time -gt $EXEC_TIME_WARN ]]; then
        status="WARNING"
    fi
    
    # Log metrics
    echo "$timestamp,$module_name,$operation,$exec_time,$memory_usage,$cpu_usage,$status,none" >> "$PERFORMANCE_LOG"
    
    # Update real-time stats
    update_realtime_stats "$module_name" "$exec_time" "$memory_usage" "$cpu_usage"
}

# Function: Update real-time statistics
update_realtime_stats() {
    local module_name="$1"
    local exec_time="$2"
    local memory_usage="$3"
    local cpu_usage="$4"
    
    local current_time
    current_time=$(date +%s)
    
    # Update metrics
    jq --arg module "$module_name" \
       --arg exec_time "$exec_time" \
       --arg memory "$memory_usage" \
       --arg cpu "$cpu_usage" \
       --arg timestamp "$current_time" \
       '
       .current_metrics.total_exec_time = ((.current_metrics.total_exec_time // 0) + ($exec_time | tonumber)) |
       .current_metrics.memory_usage = ($memory | tonumber) |
       .current_metrics.cpu_usage = ($cpu | tonumber) |
       .current_metrics.module_count = ((.current_metrics.module_count // 0) + 1) |
       .last_update = ($timestamp | tonumber)
       ' "$REAL_TIME_STATS" > "${REAL_TIME_STATS}.tmp" && mv "${REAL_TIME_STATS}.tmp" "$REAL_TIME_STATS"
    
    # Calculate performance score
    calculate_performance_score
}

# Function: Calculate overall performance score
calculate_performance_score() {
    local total_exec_time memory_usage cpu_usage module_count
    
    total_exec_time=$(jq -r '.current_metrics.total_exec_time // 0' "$REAL_TIME_STATS")
    memory_usage=$(jq -r '.current_metrics.memory_usage // 0' "$REAL_TIME_STATS")
    cpu_usage=$(jq -r '.current_metrics.cpu_usage // 0' "$REAL_TIME_STATS")
    module_count=$(jq -r '.current_metrics.module_count // 1' "$REAL_TIME_STATS")
    
    # Calculate average execution time per module
    local avg_exec_time=$((total_exec_time / module_count))
    
    # Performance scoring (0-100)
    local performance_score=100
    
    # Execution time penalty
    if [[ $avg_exec_time -gt $EXEC_TIME_CRITICAL ]]; then
        performance_score=$((performance_score - 40))
    elif [[ $avg_exec_time -gt $EXEC_TIME_WARN ]]; then
        performance_score=$((performance_score - 20))
    fi
    
    # Memory usage penalty
    if [[ $memory_usage -gt $((MEMORY_CRITICAL * 1024)) ]]; then
        performance_score=$((performance_score - 30))
    elif [[ $memory_usage -gt $((MEMORY_WARN * 1024)) ]]; then
        performance_score=$((performance_score - 15))
    fi
    
    # CPU usage penalty
    if [[ $cpu_usage -gt 80 ]]; then
        performance_score=$((performance_score - 20))
    elif [[ $cpu_usage -gt 50 ]]; then
        performance_score=$((performance_score - 10))
    fi
    
    # Determine status
    local status="optimal"
    if [[ $performance_score -lt 60 ]]; then
        status="critical"
    elif [[ $performance_score -lt 80 ]]; then
        status="warning"
    fi
    
    # Update performance score
    jq --arg score "$performance_score" \
       --arg status "$status" \
       '.performance_score = ($score | tonumber) | .status = $status' \
       "$REAL_TIME_STATS" > "${REAL_TIME_STATS}.tmp" && mv "${REAL_TIME_STATS}.tmp" "$REAL_TIME_STATS"
}

# Function: Generate optimization recommendations
generate_recommendations() {
    local performance_score memory_usage total_exec_time module_count
    
    performance_score=$(jq -r '.performance_score // 100' "$REAL_TIME_STATS")
    memory_usage=$(jq -r '.current_metrics.memory_usage // 0' "$REAL_TIME_STATS")
    total_exec_time=$(jq -r '.current_metrics.total_exec_time // 0' "$REAL_TIME_STATS")
    module_count=$(jq -r '.current_metrics.module_count // 1' "$REAL_TIME_STATS")
    
    local recommendations=()
    
    # High execution time recommendations
    local avg_exec_time=$((total_exec_time / module_count))
    if [[ $avg_exec_time -gt $EXEC_TIME_CRITICAL ]]; then
        recommendations+=("\"Reduce module count or increase cache TTL - average execution time: ${avg_exec_time}ms\"")
        recommendations+=("\"Consider disabling expensive modules like wan_ip or network stats\"")
        recommendations+=("\"Switch to 'performance' profile for optimized settings\"")
    elif [[ $avg_exec_time -gt $EXEC_TIME_WARN ]]; then
        recommendations+=("\"Consider increasing update interval to reduce frequency\"")
        recommendations+=("\"Enable background updates for network-dependent modules\"")
    fi
    
    # High memory usage recommendations
    if [[ $memory_usage -gt $((MEMORY_CRITICAL * 1024)) ]]; then
        recommendations+=("\"High memory usage detected (${memory_usage}KB) - consider reducing cache size\"")
        recommendations+=("\"Disable unused modules to reduce memory footprint\"")
    elif [[ $memory_usage -gt $((MEMORY_WARN * 1024)) ]]; then
        recommendations+=("\"Moderate memory usage (${memory_usage}KB) - monitor for growth\"")
    fi
    
    # Module-specific recommendations
    if [[ $module_count -gt 10 ]]; then
        recommendations+=("\"High module count ($module_count) - consider using essential modules only\"")
    fi
    
    # Battery-specific recommendations
    local battery_info
    if battery_info=$(get_battery_status 2>/dev/null); then
        local battery_level="${battery_info%:*}"
        local power_source="${battery_info#*:}"
        
        if [[ "$power_source" == "Battery" && $battery_level -lt 30 ]]; then
            recommendations+=("\"Low battery detected - switch to 'laptop' or 'minimal' profile\"")
            recommendations+=("\"Disable network modules on battery power\"")
        fi
    fi
    
    # Performance mode recommendations
    if [[ $performance_score -lt 70 ]]; then
        recommendations+=("\"Performance score is low ($performance_score/100) - run optimization wizard\"")
        recommendations+=("\"Consider switching to 'minimal' profile for better performance\"")
    fi
    
    # Update recommendations in real-time stats
    local recommendations_json
    recommendations_json=$(printf '%s\n' "${recommendations[@]}" | jq -R . | jq -s .)
    
    jq --argjson recs "$recommendations_json" '.recommendations = $recs' \
       "$REAL_TIME_STATS" > "${REAL_TIME_STATS}.tmp" && mv "${REAL_TIME_STATS}.tmp" "$REAL_TIME_STATS"
    
    echo "${recommendations[@]}"
}

# Function: Get battery status (helper function)
get_battery_status() {
    local battery_level=100
    local power_source="AC"
    
    # Linux battery detection
    if [[ -d "/sys/class/power_supply" ]]; then
        local battery_dir
        battery_dir=$(find /sys/class/power_supply -name "BAT*" | head -1)
        if [[ -n "$battery_dir" && -f "$battery_dir/capacity" ]]; then
            battery_level=$(cat "$battery_dir/capacity")
            if [[ -f "$battery_dir/status" ]]; then
                local status
                status=$(cat "$battery_dir/status")
                if [[ "$status" == "Discharging" ]]; then
                    power_source="Battery"
                fi
            fi
        fi
    fi
    
    echo "$battery_level:$power_source"
}

# Function: Run performance analysis
run_performance_analysis() {
    print_status "header" "Performance Analysis Report"
    echo
    
    # Calculate metrics from recent data
    local recent_data
    recent_data=$(tail -n 100 "$PERFORMANCE_LOG" 2>/dev/null || echo "")
    
    if [[ -z "$recent_data" ]]; then
        print_status "warning" "No performance data available"
        return 1
    fi
    
    # Performance metrics summary
    print_status "info" "Performance Metrics Summary (last 100 operations):"
    echo
    
    # Calculate averages
    local avg_exec_time avg_memory avg_cpu critical_count warning_count
    avg_exec_time=$(echo "$recent_data" | awk -F',' 'NR>1 {sum+=$4; count++} END {if(count>0) printf "%.1f", sum/count; else print "0"}')
    avg_memory=$(echo "$recent_data" | awk -F',' 'NR>1 {sum+=$5; count++} END {if(count>0) printf "%.1f", sum/count; else print "0"}')
    avg_cpu=$(echo "$recent_data" | awk -F',' 'NR>1 {sum+=$6; count++} END {if(count>0) printf "%.1f", sum/count; else print "0"}')
    critical_count=$(echo "$recent_data" | grep -c "CRITICAL" || echo "0")
    warning_count=$(echo "$recent_data" | grep -c "WARNING" || echo "0")
    
    print_status "metric" "Average execution time: ${avg_exec_time}ms"
    print_status "metric" "Average memory usage: ${avg_memory}KB"
    print_status "metric" "Average CPU usage: ${avg_cpu}%"
    print_status "metric" "Critical issues: $critical_count"
    print_status "metric" "Warning issues: $warning_count"
    echo
    
    # Module performance breakdown
    print_status "info" "Module Performance Breakdown:"
    echo "$recent_data" | awk -F',' 'NR>1 {
        module=$2
        exec_time=$4
        module_times[module] += exec_time
        module_counts[module]++
    }
    END {
        for (module in module_times) {
            avg = module_times[module] / module_counts[module]
            printf "  %-15s: %.1fms avg (%d samples)\n", module, avg, module_counts[module]
        }
    }' | sort -k2 -nr
    echo
    
    # Generate recommendations
    print_status "info" "Performance Recommendations:"
    local recommendations
    readarray -t recommendations < <(generate_recommendations)
    
    if [[ ${#recommendations[@]} -eq 0 ]]; then
        print_status "success" "No optimization recommendations - performance is optimal!"
    else
        for rec in "${recommendations[@]}"; do
            print_status "warning" "${rec//\"/}"
        done
    fi
    echo
    
    # Real-time status
    local performance_score status
    performance_score=$(jq -r '.performance_score // 100' "$REAL_TIME_STATS")
    status=$(jq -r '.status // "unknown"' "$REAL_TIME_STATS")
    
    print_status "header" "Overall Performance Score: $performance_score/100 ($status)"
}

# Function: Start real-time monitoring
start_monitoring() {
    local monitor_pid_file="$ANALYTICS_DIR/monitor.pid"
    
    # Check if monitoring is already running
    if [[ -f "$monitor_pid_file" ]]; then
        local pid
        pid=$(cat "$monitor_pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            print_status "info" "Performance monitoring already running (PID: $pid)"
            return 0
        else
            rm -f "$monitor_pid_file"
        fi
    fi
    
    print_status "info" "Starting performance monitoring daemon..."
    
    # Start monitoring in background
    (
        echo $$ > "$monitor_pid_file"
        
        while true; do
            # Reset metrics for new cycle
            cat > "$REAL_TIME_STATS" << 'EOF'
{
  "current_metrics": {
    "total_exec_time": 0,
    "update_frequency": 0,
    "memory_usage": 0,
    "cpu_usage": 0,
    "module_count": 0
  },
  "performance_score": 100,
  "status": "monitoring",
  "last_update": 0,
  "recommendations": []
}
EOF
            
            # Monitor for 60 seconds, then analyze
            sleep 60
            
            # Generate recommendations
            generate_recommendations >/dev/null
            
            # Log analysis timestamp
            local current_time
            current_time=$(date +%s)
            jq --arg time "$current_time" '.last_analysis = ($time | tonumber)' \
               "$OPTIMIZATION_HISTORY" > "${OPTIMIZATION_HISTORY}.tmp" && mv "${OPTIMIZATION_HISTORY}.tmp" "$OPTIMIZATION_HISTORY"
            
        done
    ) &
    
    print_status "success" "Performance monitoring started (PID: $!)"
}

# Function: Stop monitoring
stop_monitoring() {
    local monitor_pid_file="$ANALYTICS_DIR/monitor.pid"
    
    if [[ -f "$monitor_pid_file" ]]; then
        local pid
        pid=$(cat "$monitor_pid_file")
        if kill "$pid" 2>/dev/null; then
            print_status "success" "Performance monitoring stopped (PID: $pid)"
            rm -f "$monitor_pid_file"
        else
            print_status "warning" "Performance monitoring not running or already stopped"
            rm -f "$monitor_pid_file"
        fi
    else
        print_status "info" "Performance monitoring not running"
    fi
}

# Function: Show real-time dashboard
show_dashboard() {
    local refresh_interval="${1:-5}"
    
    print_status "header" "Real-time Performance Dashboard (refreshing every ${refresh_interval}s)"
    echo "Press Ctrl+C to exit"
    echo
    
    while true; do
        # Clear screen and show header
        clear
        print_status "header" "tmux-forceline Performance Dashboard - $(date)"
        echo
        
        # Show current metrics
        if [[ -f "$REAL_TIME_STATS" ]]; then
            local score status total_exec memory_usage module_count
            score=$(jq -r '.performance_score // 100' "$REAL_TIME_STATS")
            status=$(jq -r '.status // "unknown"' "$REAL_TIME_STATS")
            total_exec=$(jq -r '.current_metrics.total_exec_time // 0' "$REAL_TIME_STATS")
            memory_usage=$(jq -r '.current_metrics.memory_usage // 0' "$REAL_TIME_STATS")
            module_count=$(jq -r '.current_metrics.module_count // 0' "$REAL_TIME_STATS")
            
            echo "Performance Score: $score/100 ($status)"
            echo "Total Execution Time: ${total_exec}ms"
            echo "Memory Usage: ${memory_usage}KB"
            echo "Active Modules: $module_count"
            echo
            
            # Show recent recommendations
            local recommendations_count
            recommendations_count=$(jq -r '.recommendations | length' "$REAL_TIME_STATS")
            if [[ $recommendations_count -gt 0 ]]; then
                echo "Current Recommendations:"
                jq -r '.recommendations[]' "$REAL_TIME_STATS" | sed 's/^/  • /'
                echo
            fi
        fi
        
        # Show recent performance log entries
        if [[ -f "$PERFORMANCE_LOG" ]]; then
            echo "Recent Activity:"
            tail -n 5 "$PERFORMANCE_LOG" | column -t -s ',' | sed 's/^/  /'
        fi
        
        sleep "$refresh_interval"
    done
}

# Function: Apply automatic optimizations
apply_auto_optimizations() {
    print_status "info" "Applying automatic performance optimizations..."
    
    local recommendations
    readarray -t recommendations < <(generate_recommendations)
    
    local optimizations_applied=0
    
    for rec in "${recommendations[@]}"; do
        case "$rec" in
            *"Switch to 'performance' profile"*)
                if [[ -x "$FORCELINE_DIR/utils/adaptive_profile_manager.sh" ]]; then
                    print_status "info" "Applying performance profile..."
                    "$FORCELINE_DIR/utils/adaptive_profile_manager.sh" --apply=performance --quiet
                    optimizations_applied=$((optimizations_applied + 1))
                fi
                ;;
            *"increase cache TTL"*)
                print_status "info" "Increasing cache TTL to 10 seconds..."
                tmux set-option -g @forceline_cache_ttl "10"
                optimizations_applied=$((optimizations_applied + 1))
                ;;
            *"increase update interval"*)
                print_status "info" "Increasing update interval to 2 seconds..."
                tmux set-option -g @forceline_update_interval "2"
                optimizations_applied=$((optimizations_applied + 1))
                ;;
        esac
    done
    
    if [[ $optimizations_applied -gt 0 ]]; then
        print_status "success" "Applied $optimizations_applied automatic optimizations"
        
        # Log optimization
        local current_time
        current_time=$(date +%s)
        local optimization_record="{\"timestamp\": $current_time, \"type\": \"auto\", \"count\": $optimizations_applied, \"recommendations\": $(printf '%s\n' "${recommendations[@]}" | jq -R . | jq -s .)}"
        
        jq --argjson opt "$optimization_record" '.optimizations += [$opt]' \
           "$OPTIMIZATION_HISTORY" > "${OPTIMIZATION_HISTORY}.tmp" && mv "${OPTIMIZATION_HISTORY}.tmp" "$OPTIMIZATION_HISTORY"
    else
        print_status "info" "No automatic optimizations available"
    fi
}

# Function: Export performance data
export_performance_data() {
    local output_file="${1:-performance_export_$(date +%Y%m%d_%H%M%S).json}"
    
    print_status "info" "Exporting performance data to: $output_file"
    
    # Combine all data
    local export_data
    export_data=$(jq -n --slurpfile realtime "$REAL_TIME_STATS" \
                         --slurpfile history "$OPTIMIZATION_HISTORY" \
                         '{
                           "export_timestamp": now,
                           "version": "3.0",
                           "realtime_stats": $realtime[0],
                           "optimization_history": $history[0],
                           "performance_log_sample": []
                         }')
    
    # Add performance log sample (last 1000 entries)
    if [[ -f "$PERFORMANCE_LOG" ]]; then
        local log_sample
        log_sample=$(tail -n 1000 "$PERFORMANCE_LOG" | jq -R -s 'split("\n")[:-1]')
        export_data=$(echo "$export_data" | jq --argjson sample "$log_sample" '.performance_log_sample = $sample')
    fi
    
    echo "$export_data" > "$output_file"
    print_status "success" "Performance data exported to: $output_file"
}

# Function: Main command dispatcher
main() {
    local command="${1:-dashboard}"
    
    # Initialize analytics
    init_analytics
    
    case "$command" in
        "start")
            start_monitoring
            ;;
        "stop")
            stop_monitoring
            ;;
        "dashboard")
            local interval="${2:-5}"
            show_dashboard "$interval"
            ;;
        "analyze")
            run_performance_analysis
            ;;
        "recommend")
            print_status "header" "Performance Recommendations"
            echo
            local recommendations
            readarray -t recommendations < <(generate_recommendations)
            if [[ ${#recommendations[@]} -eq 0 ]]; then
                print_status "success" "No recommendations - performance is optimal!"
            else
                for rec in "${recommendations[@]}"; do
                    print_status "warning" "${rec//\"/}"
                done
            fi
            ;;
        "optimize")
            apply_auto_optimizations
            ;;
        "export")
            local output_file="$2"
            export_performance_data "$output_file"
            ;;
        "capture")
            local module="$2"
            local operation="${3:-update}"
            local start_time="$4"
            local end_time="$5"
            capture_module_metrics "$module" "$operation" "$start_time" "$end_time"
            ;;
        *)
            echo "Usage: $0 {start|stop|dashboard|analyze|recommend|optimize|export|capture}"
            echo
            echo "Commands:"
            echo "  start                     Start performance monitoring daemon"
            echo "  stop                      Stop performance monitoring daemon"
            echo "  dashboard [interval]      Show real-time performance dashboard"
            echo "  analyze                   Run comprehensive performance analysis"
            echo "  recommend                 Show optimization recommendations"
            echo "  optimize                  Apply automatic optimizations"
            echo "  export [file]             Export performance data to JSON"
            echo "  capture <module> <op> <start> <end>  Capture module metrics"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"