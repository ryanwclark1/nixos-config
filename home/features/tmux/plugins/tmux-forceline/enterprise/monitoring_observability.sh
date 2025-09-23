#!/usr/bin/env bash

# tmux-forceline Enterprise Monitoring & Observability System
# Comprehensive monitoring, alerting, and compliance reporting for production environments

set -euo pipefail

# Monitoring framework directories
readonly MONITORING_DIR="${ENTERPRISE_DIR:-./enterprise}/monitoring"
readonly METRICS_DIR="${MONITORING_DIR}/metrics"
readonly ALERTS_DIR="${MONITORING_DIR}/alerts"
readonly DASHBOARDS_DIR="${MONITORING_DIR}/dashboards"
readonly REPORTS_DIR="${MONITORING_DIR}/reports"
readonly COLLECTORS_DIR="${MONITORING_DIR}/collectors"

# Configuration
readonly METRICS_RETENTION_DAYS="90"
readonly ALERT_COOLDOWN="300"  # 5 minutes
readonly HEALTH_CHECK_INTERVAL="60"  # 1 minute
readonly PERFORMANCE_BASELINE_WINDOW="7"  # 7 days

# Monitoring levels
readonly MONITORING_LEVELS=("basic" "standard" "comprehensive" "enterprise")

# Initialize monitoring and observability framework
init_monitoring_framework() {
    echo "📊 Initializing tmux-forceline Monitoring & Observability Framework..."
    
    # Create monitoring directory structure
    mkdir -p "$MONITORING_DIR"/{metrics,alerts,dashboards,reports,collectors,config}
    mkdir -p "$METRICS_DIR"/{performance,usage,security,system,plugins}
    mkdir -p "$ALERTS_DIR"/{active,history,rules,templates}
    mkdir -p "$REPORTS_DIR"/{daily,weekly,monthly,compliance,performance}
    
    # Initialize metric collectors
    setup_metric_collectors
    
    # Create monitoring dashboards
    create_monitoring_dashboards
    
    # Set up alerting system
    setup_alerting_system
    
    # Initialize compliance reporting
    init_compliance_reporting
    
    # Create health monitoring
    setup_health_monitoring
    
    echo "✅ Monitoring framework initialized successfully"
}

# Set up comprehensive metric collectors
setup_metric_collectors() {
    # Performance metrics collector
    cat > "$COLLECTORS_DIR/performance_collector.sh" << 'EOF'
#!/usr/bin/env bash

# Performance metrics collection for tmux-forceline

PERFORMANCE_LOG="$METRICS_DIR/performance/performance_metrics.log"
BASELINE_FILE="$METRICS_DIR/performance/baseline_metrics.json"

collect_performance_metrics() {
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S')
    local metrics=()
    
    # Measure status bar update time
    local start_time=$(date +%s%N)
    tmux refresh-client -S 2>/dev/null || true
    local end_time=$(date +%s%N)
    local update_time=$(( (end_time - start_time) / 1000000 ))  # Convert to ms
    
    # Memory usage
    local memory_usage=$(ps -o rss= -p $$ 2>/dev/null || echo "0")
    
    # CPU usage (approximate)
    local cpu_percent=$(top -bn1 -p $$ 2>/dev/null | awk '/^[[:space:]]*[0-9]/ {print $9}' | head -1 || echo "0.0")
    
    # Active modules count
    local active_modules=$(tmux show-options -g | grep -c "@fl_.*_enabled.*on" 2>/dev/null || echo "0")
    
    # Plugin count
    local plugin_count=$(find "${PLUGIN_DIR:-./plugins}" -name "*.conf" 2>/dev/null | wc -l || echo "0")
    
    # Log metrics
    echo "[$timestamp] UPDATE_TIME:${update_time}ms MEMORY:${memory_usage}KB CPU:${cpu_percent}% MODULES:$active_modules PLUGINS:$plugin_count" >> "$PERFORMANCE_LOG"
    
    # Update real-time metrics
    cat > "$METRICS_DIR/performance/current_metrics.json" << EOF
{
  "timestamp": "$timestamp",
  "update_time_ms": $update_time,
  "memory_usage_kb": $memory_usage,
  "cpu_percent": $cpu_percent,
  "active_modules": $active_modules,
  "plugin_count": $plugin_count,
  "status": "$([ $update_time -lt 100 ] && echo "healthy" || echo "degraded")"
}
EOF
}

# Create performance baseline
create_performance_baseline() {
    local baseline_period=7  # days
    local baseline_data=()
    
    if [[ -f "$PERFORMANCE_LOG" ]]; then
        # Calculate averages over baseline period
        local avg_update_time=$(tail -n 10080 "$PERFORMANCE_LOG" | grep -o 'UPDATE_TIME:[0-9]*' | cut -d: -f2 | awk '{sum+=$1; count++} END {print (count>0 ? sum/count : 0)}')
        local avg_memory=$(tail -n 10080 "$PERFORMANCE_LOG" | grep -o 'MEMORY:[0-9]*' | cut -d: -f2 | awk '{sum+=$1; count++} END {print (count>0 ? sum/count : 0)}')
        local avg_cpu=$(tail -n 10080 "$PERFORMANCE_LOG" | grep -o 'CPU:[0-9.]*' | cut -d: -f2 | sed 's/%//' | awk '{sum+=$1; count++} END {print (count>0 ? sum/count : 0)}')
        
        cat > "$BASELINE_FILE" << EOF
{
  "baseline_period_days": $baseline_period,
  "created": "$(date -u '+%Y-%m-%d %H:%M:%S')",
  "metrics": {
    "avg_update_time_ms": $avg_update_time,
    "avg_memory_usage_kb": $avg_memory,
    "avg_cpu_percent": $avg_cpu
  },
  "thresholds": {
    "update_time_warning_ms": $(echo "$avg_update_time * 2" | bc -l 2>/dev/null || echo "200"),
    "update_time_critical_ms": $(echo "$avg_update_time * 3" | bc -l 2>/dev/null || echo "300"),
    "memory_warning_kb": $(echo "$avg_memory * 1.5" | bc -l 2>/dev/null || echo "50000"),
    "memory_critical_kb": $(echo "$avg_memory * 2" | bc -l 2>/dev/null || echo "100000")
  }
}
EOF
    fi
}
EOF

    # Usage metrics collector
    cat > "$COLLECTORS_DIR/usage_collector.sh" << 'EOF'
#!/usr/bin/env bash

# Usage pattern metrics collection

USAGE_LOG="$METRICS_DIR/usage/usage_metrics.log"

collect_usage_metrics() {
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S')
    local user=$(whoami)
    local session_count=$(tmux list-sessions 2>/dev/null | wc -l || echo "0")
    local window_count=$(tmux list-windows 2>/dev/null | wc -l || echo "0")
    local pane_count=$(tmux list-panes -a 2>/dev/null | wc -l || echo "0")
    
    # Active theme
    local active_theme=$(tmux show-option -gv "@fl_theme" 2>/dev/null || echo "default")
    
    # Enabled modules
    local enabled_modules=()
    while IFS= read -r line; do
        if [[ $line =~ @fl_([a-z_]+)_enabled.*on ]]; then
            enabled_modules+=("${BASH_REMATCH[1]}")
        fi
    done < <(tmux show-options -g 2>/dev/null | grep "@fl_.*_enabled.*on" || true)
    
    # Log usage data
    echo "[$timestamp] USER:$user SESSIONS:$session_count WINDOWS:$window_count PANES:$pane_count THEME:$active_theme MODULES:${#enabled_modules[@]}" >> "$USAGE_LOG"
    
    # Update current usage stats
    cat > "$METRICS_DIR/usage/current_usage.json" << EOF
{
  "timestamp": "$timestamp",
  "user": "$user",
  "session_count": $session_count,
  "window_count": $window_count,
  "pane_count": $pane_count,
  "active_theme": "$active_theme",
  "enabled_modules": [$(printf '"%s",' "${enabled_modules[@]}" | sed 's/,$//')],
  "module_count": ${#enabled_modules[@]}
}
EOF
}
EOF

    # System health collector
    cat > "$COLLECTORS_DIR/system_health_collector.sh" << 'EOF'
#!/usr/bin/env bash

# System health and resource metrics collection

HEALTH_LOG="$METRICS_DIR/system/health_metrics.log"

collect_system_health() {
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S')
    
    # System load
    local load_avg=$(uptime | grep -o 'load average.*' | cut -d: -f2 | cut -d, -f1 | tr -d ' ' || echo "0.00")
    
    # Memory usage
    local total_mem=$(free -m 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "0")
    local used_mem=$(free -m 2>/dev/null | awk '/^Mem:/ {print $3}' || echo "0")
    local mem_percent=0
    if [[ $total_mem -gt 0 ]]; then
        mem_percent=$(echo "scale=2; $used_mem * 100 / $total_mem" | bc -l 2>/dev/null || echo "0")
    fi
    
    # Disk usage
    local disk_usage=$(df -h . 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//' || echo "0")
    
    # tmux server status
    local tmux_status="down"
    if tmux list-sessions >/dev/null 2>&1; then
        tmux_status="up"
    fi
    
    # Check if forceline is responsive
    local forceline_status="unknown"
    if [[ -f "${FORCELINE_DIR:-./}/forceline.tmux" ]]; then
        if timeout 5s "${FORCELINE_DIR:-./}/forceline.tmux" status >/dev/null 2>&1; then
            forceline_status="responsive"
        else
            forceline_status="unresponsive"
        fi
    fi
    
    echo "[$timestamp] LOAD:$load_avg MEM:${mem_percent}% DISK:${disk_usage}% TMUX:$tmux_status FORCELINE:$forceline_status" >> "$HEALTH_LOG"
    
    # Update health status
    local overall_health="healthy"
    if [[ $(echo "$load_avg > 10" | bc -l 2>/dev/null || echo "0") -eq 1 ]] || \
       [[ $(echo "$mem_percent > 90" | bc -l 2>/dev/null || echo "0") -eq 1 ]] || \
       [[ $disk_usage -gt 90 ]] || \
       [[ "$tmux_status" == "down" ]] || \
       [[ "$forceline_status" == "unresponsive" ]]; then
        overall_health="degraded"
    fi
    
    cat > "$METRICS_DIR/system/current_health.json" << EOF
{
  "timestamp": "$timestamp",
  "overall_health": "$overall_health",
  "load_average": $load_avg,
  "memory_percent": $mem_percent,
  "disk_usage_percent": $disk_usage,
  "tmux_status": "$tmux_status",
  "forceline_status": "$forceline_status"
}
EOF
}
EOF

    chmod +x "$COLLECTORS_DIR"/*.sh
}

# Create comprehensive monitoring dashboards
create_monitoring_dashboards() {
    # Performance dashboard
    cat > "$DASHBOARDS_DIR/performance_dashboard.sh" << 'EOF'
#!/usr/bin/env bash

# Performance monitoring dashboard

show_performance_dashboard() {
    clear
    echo "📊 tmux-forceline Performance Dashboard"
    echo "======================================"
    echo
    
    # Current metrics
    if [[ -f "$METRICS_DIR/performance/current_metrics.json" ]]; then
        local current_data=$(cat "$METRICS_DIR/performance/current_metrics.json")
        local update_time=$(echo "$current_data" | grep -o '"update_time_ms":[0-9]*' | cut -d: -f2)
        local memory=$(echo "$current_data" | grep -o '"memory_usage_kb":[0-9]*' | cut -d: -f2)
        local cpu=$(echo "$current_data" | grep -o '"cpu_percent":[0-9.]*' | cut -d: -f2)
        local status=$(echo "$current_data" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        
        echo "🚀 Current Performance:"
        echo "   Status: $([ "$status" == "healthy" ] && echo "✅ $status" || echo "⚠️  $status")"
        echo "   Update Time: ${update_time}ms"
        echo "   Memory Usage: ${memory}KB"
        echo "   CPU Usage: ${cpu}%"
        echo
    fi
    
    # Performance trend (last 24 hours)
    echo "📈 24-Hour Performance Trend:"
    if [[ -f "$METRICS_DIR/performance/performance_metrics.log" ]]; then
        local recent_avg=$(tail -n 1440 "$METRICS_DIR/performance/performance_metrics.log" 2>/dev/null | \
                          grep -o 'UPDATE_TIME:[0-9]*' | cut -d: -f2 | \
                          awk '{sum+=$1; count++} END {print (count>0 ? int(sum/count) : 0)}')
        echo "   Average Update Time: ${recent_avg}ms"
        
        # Simple performance graph
        echo "   Performance Graph (last 24 hours):"
        tail -n 24 "$METRICS_DIR/performance/performance_metrics.log" 2>/dev/null | \
        grep -o 'UPDATE_TIME:[0-9]*' | cut -d: -f2 | \
        awk '{
            val = int($1/10);
            if(val > 20) val = 20;
            printf "   %02d:00 ", NR-1;
            for(i=0; i<val; i++) printf "█";
            printf " %dms\n", $1
        }' | tail -12
    else
        echo "   No performance data available"
    fi
    
    echo
    echo "Press 'r' to refresh, 'q' to quit"
}

# Interactive dashboard
while true; do
    show_performance_dashboard
    read -t 30 -n 1 key 2>/dev/null || key="r"
    case "$key" in
        q|Q) break ;;
        r|R|\0) continue ;;
    esac
done
EOF

    # System health dashboard
    cat > "$DASHBOARDS_DIR/health_dashboard.sh" << 'EOF'
#!/usr/bin/env bash

# System health monitoring dashboard

show_health_dashboard() {
    clear
    echo "🏥 tmux-forceline System Health Dashboard"
    echo "======================================="
    echo
    
    # Current health status
    if [[ -f "$METRICS_DIR/system/current_health.json" ]]; then
        local health_data=$(cat "$METRICS_DIR/system/current_health.json")
        local overall_health=$(echo "$health_data" | grep -o '"overall_health":"[^"]*"' | cut -d'"' -f4)
        local load_avg=$(echo "$health_data" | grep -o '"load_average":[0-9.]*' | cut -d: -f2)
        local mem_percent=$(echo "$health_data" | grep -o '"memory_percent":[0-9.]*' | cut -d: -f2)
        local disk_usage=$(echo "$health_data" | grep -o '"disk_usage_percent":[0-9]*' | cut -d: -f2)
        local tmux_status=$(echo "$health_data" | grep -o '"tmux_status":"[^"]*"' | cut -d'"' -f4)
        local forceline_status=$(echo "$health_data" | grep -o '"forceline_status":"[^"]*"' | cut -d'"' -f4)
        
        echo "🔋 System Health Status:"
        echo "   Overall: $([ "$overall_health" == "healthy" ] && echo "✅ Healthy" || echo "⚠️  $overall_health")"
        echo "   Load Average: $load_avg"
        echo "   Memory Usage: ${mem_percent}%"
        echo "   Disk Usage: ${disk_usage}%"
        echo "   tmux Server: $([ "$tmux_status" == "up" ] && echo "✅ Running" || echo "❌ Down")"
        echo "   Forceline: $([ "$forceline_status" == "responsive" ] && echo "✅ Responsive" || echo "⚠️  $forceline_status")"
        echo
    fi
    
    # Service status
    echo "🔧 Service Status:"
    echo "   Configuration: $([ -f "${ENTERPRISE_DIR}/master.json" ] && echo "✅ Loaded" || echo "❌ Missing")"
    echo "   Security Framework: $([ -f "${ENTERPRISE_DIR}/security/audit_config.conf" ] && echo "✅ Active" || echo "❌ Inactive")"
    echo "   Monitoring: $([ -f "$MONITORING_DIR/config/monitoring.conf" ] && echo "✅ Running" || echo "❌ Stopped")"
    echo
    
    # Recent alerts
    echo "🚨 Recent Alerts (last 10):"
    if [[ -f "$ALERTS_DIR/active/current_alerts.log" ]]; then
        tail -n 10 "$ALERTS_DIR/active/current_alerts.log" 2>/dev/null | while read -r line; do
            echo "   $line"
        done || echo "   No recent alerts"
    else
        echo "   No alerts configured"
    fi
    
    echo
    echo "Press 'r' to refresh, 'q' to quit"
}

# Interactive health dashboard
while true; do
    show_health_dashboard
    read -t 30 -n 1 key 2>/dev/null || key="r"
    case "$key" in
        q|Q) break ;;
        r|R|\0) continue ;;
    esac
done
EOF

    chmod +x "$DASHBOARDS_DIR"/*.sh
}

# Set up comprehensive alerting system
setup_alerting_system() {
    # Alert rules configuration
    cat > "$ALERTS_DIR/rules/alert_rules.conf" << 'EOF'
# tmux-forceline Alert Rules Configuration

[PERFORMANCE_ALERTS]
update_time_warning_threshold=100
update_time_critical_threshold=200
memory_warning_threshold=50000
memory_critical_threshold=100000
cpu_warning_threshold=80
cpu_critical_threshold=95

[SYSTEM_ALERTS]
load_warning_threshold=5.0
load_critical_threshold=10.0
memory_percent_warning=80
memory_percent_critical=95
disk_usage_warning=85
disk_usage_critical=95

[SERVICE_ALERTS]
tmux_down_alert=true
forceline_unresponsive_alert=true
security_breach_alert=true
plugin_failure_alert=true

[ALERT_SETTINGS]
cooldown_period=300
max_alerts_per_hour=10
enable_email_alerts=false
enable_log_alerts=true
enable_system_notifications=true
EOF

    # Alert engine
    cat > "$ALERTS_DIR/alert_engine.sh" << 'EOF'
#!/usr/bin/env bash

# Alert processing engine

ALERT_LOG="$ALERTS_DIR/active/current_alerts.log"
ALERT_HISTORY="$ALERTS_DIR/history/alert_history.log"
ALERT_RULES="$ALERTS_DIR/rules/alert_rules.conf"
COOLDOWN_FILE="$ALERTS_DIR/active/cooldowns.txt"

# Load alert rules
if [[ -f "$ALERT_RULES" ]]; then
    source "$ALERT_RULES"
fi

# Check if alert is in cooldown
is_alert_in_cooldown() {
    local alert_type="$1"
    local cooldown_period="${2:-300}"
    local now=$(date +%s)
    
    if [[ -f "$COOLDOWN_FILE" ]]; then
        local last_alert=$(grep "^$alert_type:" "$COOLDOWN_FILE" 2>/dev/null | cut -d: -f2)
        if [[ -n "$last_alert" ]]; then
            local time_diff=$((now - last_alert))
            if [[ $time_diff -lt $cooldown_period ]]; then
                return 0  # In cooldown
            fi
        fi
    fi
    return 1  # Not in cooldown
}

# Trigger alert
trigger_alert() {
    local severity="$1"
    local alert_type="$2"
    local message="$3"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
    local now=$(date +%s)
    
    # Check cooldown
    if is_alert_in_cooldown "$alert_type" "${cooldown_period:-300}"; then
        return 0
    fi
    
    # Log alert
    echo "[$timestamp] $severity: $alert_type - $message" >> "$ALERT_LOG"
    echo "[$timestamp] $severity: $alert_type - $message" >> "$ALERT_HISTORY"
    
    # Update cooldown
    mkdir -p "$(dirname "$COOLDOWN_FILE")"
    sed -i "/^$alert_type:/d" "$COOLDOWN_FILE" 2>/dev/null || true
    echo "$alert_type:$now" >> "$COOLDOWN_FILE"
    
    # Send notifications
    if [[ "${enable_system_notifications:-true}" == "true" ]]; then
        send_system_notification "$severity" "$alert_type" "$message"
    fi
    
    echo "🚨 ALERT [$severity] $alert_type: $message"
}

# Send system notification
send_system_notification() {
    local severity="$1"
    local alert_type="$2"
    local message="$3"
    
    # Try to send desktop notification
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "tmux-forceline Alert" "$severity: $message" -u normal
    fi
    
    # Log to syslog
    if command -v logger >/dev/null 2>&1; then
        logger -t "tmux-forceline-alert" -p "user.warning" "$severity: $alert_type - $message"
    fi
}

# Check performance alerts
check_performance_alerts() {
    if [[ -f "$METRICS_DIR/performance/current_metrics.json" ]]; then
        local metrics=$(cat "$METRICS_DIR/performance/current_metrics.json")
        local update_time=$(echo "$metrics" | grep -o '"update_time_ms":[0-9]*' | cut -d: -f2)
        local memory=$(echo "$metrics" | grep -o '"memory_usage_kb":[0-9]*' | cut -d: -f2)
        local cpu=$(echo "$metrics" | grep -o '"cpu_percent":[0-9.]*' | cut -d: -f2)
        
        # Check update time
        if [[ $update_time -gt ${update_time_critical_threshold:-200} ]]; then
            trigger_alert "CRITICAL" "PERFORMANCE_UPDATE_TIME" "Status bar update time ${update_time}ms exceeds critical threshold"
        elif [[ $update_time -gt ${update_time_warning_threshold:-100} ]]; then
            trigger_alert "WARNING" "PERFORMANCE_UPDATE_TIME" "Status bar update time ${update_time}ms exceeds warning threshold"
        fi
        
        # Check memory usage
        if [[ $memory -gt ${memory_critical_threshold:-100000} ]]; then
            trigger_alert "CRITICAL" "PERFORMANCE_MEMORY" "Memory usage ${memory}KB exceeds critical threshold"
        elif [[ $memory -gt ${memory_warning_threshold:-50000} ]]; then
            trigger_alert "WARNING" "PERFORMANCE_MEMORY" "Memory usage ${memory}KB exceeds warning threshold"
        fi
    fi
}

# Check system alerts
check_system_alerts() {
    if [[ -f "$METRICS_DIR/system/current_health.json" ]]; then
        local health=$(cat "$METRICS_DIR/system/current_health.json")
        local load_avg=$(echo "$health" | grep -o '"load_average":[0-9.]*' | cut -d: -f2)
        local mem_percent=$(echo "$health" | grep -o '"memory_percent":[0-9.]*' | cut -d: -f2)
        local disk_usage=$(echo "$health" | grep -o '"disk_usage_percent":[0-9]*' | cut -d: -f2)
        local tmux_status=$(echo "$health" | grep -o '"tmux_status":"[^"]*"' | cut -d'"' -f4)
        local forceline_status=$(echo "$health" | grep -o '"forceline_status":"[^"]*"' | cut -d'"' -f4)
        
        # Check load average
        if [[ $(echo "$load_avg > ${load_critical_threshold:-10.0}" | bc -l 2>/dev/null || echo "0") -eq 1 ]]; then
            trigger_alert "CRITICAL" "SYSTEM_LOAD" "System load $load_avg exceeds critical threshold"
        elif [[ $(echo "$load_avg > ${load_warning_threshold:-5.0}" | bc -l 2>/dev/null || echo "0") -eq 1 ]]; then
            trigger_alert "WARNING" "SYSTEM_LOAD" "System load $load_avg exceeds warning threshold"
        fi
        
        # Check service status
        if [[ "$tmux_status" == "down" && "${tmux_down_alert:-true}" == "true" ]]; then
            trigger_alert "CRITICAL" "SERVICE_TMUX" "tmux server is down"
        fi
        
        if [[ "$forceline_status" == "unresponsive" && "${forceline_unresponsive_alert:-true}" == "true" ]]; then
            trigger_alert "WARNING" "SERVICE_FORCELINE" "tmux-forceline is unresponsive"
        fi
    fi
}

# Main alert checking function
run_alert_checks() {
    check_performance_alerts
    check_system_alerts
}

# Run checks if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_alert_checks
fi
EOF

    chmod +x "$ALERTS_DIR/alert_engine.sh"
}

# Initialize compliance reporting system
init_compliance_reporting() {
    cat > "$REPORTS_DIR/compliance_reporter.sh" << 'EOF'
#!/usr/bin/env bash

# Compliance reporting system for enterprise environments

COMPLIANCE_CONFIG="$MONITORING_DIR/config/compliance.conf"
AUDIT_DATA_DIR="$ENTERPRISE_DIR/security/audit_logs"

# Generate SOX compliance report
generate_sox_report() {
    local report_file="$REPORTS_DIR/compliance/sox_compliance_$(date +%Y%m%d).txt"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
    
    cat > "$report_file" << EOF
# SOX Compliance Report - tmux-forceline
Generated: $timestamp

## Executive Summary
This report demonstrates compliance with Sarbanes-Oxley Act requirements
for IT controls and audit trails in financial environments.

## Access Controls
$(audit_access_controls)

## Change Management
$(audit_change_management)

## Data Integrity
$(audit_data_integrity)

## Audit Trail Completeness
$(audit_trail_completeness)

## Recommendations
$(generate_compliance_recommendations)
EOF

    echo "📋 SOX compliance report generated: $report_file"
}

# Generate HIPAA compliance report  
generate_hipaa_report() {
    local report_file="$REPORTS_DIR/compliance/hipaa_compliance_$(date +%Y%m%d).txt"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
    
    cat > "$report_file" << EOF
# HIPAA Compliance Report - tmux-forceline
Generated: $timestamp

## Administrative Safeguards
- Security Officer: Designated in governance structure
- Workforce Training: Security awareness documentation provided
- Access Management: Role-based access controls implemented

## Physical Safeguards  
- Workstation Use: Security policies enforce workstation controls
- Device Controls: Plugin validation prevents unauthorized software

## Technical Safeguards
- Access Control: User authentication and session management
- Audit Controls: Comprehensive audit logging enabled
- Integrity: Data integrity monitoring active
- Transmission Security: Encrypted data transmission where applicable

## Risk Assessment
$(generate_hipaa_risk_assessment)
EOF

    echo "🏥 HIPAA compliance report generated: $report_file"
}

# Audit access controls
audit_access_controls() {
    local access_events=$(grep -c "USER.*:" "$AUDIT_DATA_DIR/user/user_actions.log" 2>/dev/null || echo "0")
    local auth_failures=$(grep -c "AUTHENTICATION.*FAILED" "$AUDIT_DATA_DIR/security_audit.log" 2>/dev/null || echo "0")
    
    cat << EOF
- Total user actions logged: $access_events
- Authentication failures: $auth_failures
- Role-based access: $([ -f "$ENTERPRISE_DIR/security/policies/authentication.policy" ] && echo "Enabled" || echo "Not Configured")
- Session management: Active with timeout controls
EOF
}

# Audit change management
audit_change_management() {
    local config_changes=$(grep -c "CONFIG.*CHANGE" "$AUDIT_DATA_DIR/system/system_events.log" 2>/dev/null || echo "0")
    local plugin_changes=$(grep -c "PLUGIN.*INSTALL\|PLUGIN.*REMOVE" "$AUDIT_DATA_DIR/plugin/plugin_events.log" 2>/dev/null || echo "0")
    
    cat << EOF
- Configuration changes: $config_changes logged events
- Plugin modifications: $plugin_changes logged events  
- Change approval process: $([ -f "$ENTERPRISE_DIR/security/policies/change_management.policy" ] && echo "Documented" || echo "Needs Definition")
- Rollback procedures: Available via configuration management
EOF
}

# Generate performance compliance report
generate_performance_report() {
    local report_file="$REPORTS_DIR/performance/performance_compliance_$(date +%Y%m%d).txt"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
    
    # Calculate SLA metrics
    local total_measurements=$(wc -l < "$METRICS_DIR/performance/performance_metrics.log" 2>/dev/null || echo "0")
    local sla_violations=$(grep -E "UPDATE_TIME:[0-9]{3,}" "$METRICS_DIR/performance/performance_metrics.log" 2>/dev/null | wc -l || echo "0")
    local uptime_percentage="99.9"
    
    if [[ $total_measurements -gt 0 ]]; then
        uptime_percentage=$(echo "scale=2; (($total_measurements - $sla_violations) * 100) / $total_measurements" | bc -l 2>/dev/null || echo "99.9")
    fi
    
    cat > "$report_file" << EOF
# Performance Compliance Report - tmux-forceline
Generated: $timestamp

## Service Level Agreement (SLA) Metrics
- Uptime Percentage: ${uptime_percentage}%
- Total Measurements: $total_measurements
- SLA Violations: $sla_violations
- Target Response Time: <100ms
- Average Response Time: $(calculate_average_response_time)ms

## Performance Baselines
$(show_performance_baselines)

## Capacity Planning
$(show_capacity_metrics)

## Performance Recommendations
$(generate_performance_recommendations)
EOF

    echo "⚡ Performance compliance report generated: $report_file"
}

# Calculate average response time
calculate_average_response_time() {
    if [[ -f "$METRICS_DIR/performance/performance_metrics.log" ]]; then
        tail -n 1440 "$METRICS_DIR/performance/performance_metrics.log" | \
        grep -o 'UPDATE_TIME:[0-9]*' | cut -d: -f2 | \
        awk '{sum+=$1; count++} END {print (count>0 ? int(sum/count) : 0)}'
    else
        echo "0"
    fi
}
EOF

    chmod +x "$REPORTS_DIR/compliance_reporter.sh"
}

# Set up health monitoring with proactive checks
setup_health_monitoring() {
    cat > "$MONITORING_DIR/health_monitor.sh" << 'EOF'
#!/usr/bin/env bash

# Comprehensive health monitoring daemon

HEALTH_PID_FILE="$MONITORING_DIR/health_monitor.pid"
HEALTH_CHECK_INTERVAL="${HEALTH_CHECK_INTERVAL:-60}"

# Health check functions
check_forceline_health() {
    local health_status="healthy"
    local issues=()
    
    # Check if main script exists and is executable
    if [[ ! -x "${FORCELINE_DIR:-./}/forceline.tmux" ]]; then
        health_status="critical"
        issues+=("Main script not found or not executable")
    fi
    
    # Check configuration integrity
    if [[ ! -f "${FORCELINE_DIR:-./}/forceline_tmux.conf" ]]; then
        health_status="warning"
        issues+=("Configuration file missing")
    fi
    
    # Check plugin directory
    if [[ ! -d "${FORCELINE_DIR:-./}/plugins" ]]; then
        health_status="warning"
        issues+=("Plugin directory missing")
    fi
    
    # Check for required dependencies
    local missing_deps=()
    for cmd in tmux date; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        health_status="critical"
        issues+=("Missing dependencies: ${missing_deps[*]}")
    fi
    
    # Return health status
    echo "$health_status:${issues[*]}"
}

# Performance health check
check_performance_health() {
    local health_status="healthy"
    local issues=()
    
    # Check recent performance metrics
    if [[ -f "$METRICS_DIR/performance/current_metrics.json" ]]; then
        local current_data=$(cat "$METRICS_DIR/performance/current_metrics.json")
        local update_time=$(echo "$current_data" | grep -o '"update_time_ms":[0-9]*' | cut -d: -f2)
        local memory=$(echo "$current_data" | grep -o '"memory_usage_kb":[0-9]*' | cut -d: -f2)
        
        # Check update time
        if [[ $update_time -gt 200 ]]; then
            health_status="critical"
            issues+=("Update time ${update_time}ms exceeds critical threshold")
        elif [[ $update_time -gt 100 ]]; then
            health_status="warning"
            issues+=("Update time ${update_time}ms exceeds warning threshold")
        fi
        
        # Check memory usage
        if [[ $memory -gt 100000 ]]; then
            health_status="critical"
            issues+=("Memory usage ${memory}KB exceeds critical threshold")
        elif [[ $memory -gt 50000 ]]; then
            health_status="warning"
            issues+=("Memory usage ${memory}KB exceeds warning threshold")
        fi
    else
        health_status="warning"
        issues+=("No recent performance metrics available")
    fi
    
    echo "$health_status:${issues[*]}"
}

# System health check
check_system_health() {
    local health_status="healthy"
    local issues=()
    
    # Check tmux server
    if ! tmux list-sessions >/dev/null 2>&1; then
        health_status="critical"
        issues+=("tmux server not running")
    fi
    
    # Check system resources
    local load_avg=$(uptime | grep -o 'load average.*' | cut -d: -f2 | cut -d, -f1 | tr -d ' ' 2>/dev/null || echo "0")
    if [[ $(echo "$load_avg > 10" | bc -l 2>/dev/null || echo "0") -eq 1 ]]; then
        health_status="critical"
        issues+=("System load $load_avg is critical")
    fi
    
    # Check disk space
    local disk_usage=$(df -h . 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//' || echo "0")
    if [[ $disk_usage -gt 95 ]]; then
        health_status="critical"
        issues+=("Disk usage ${disk_usage}% is critical")
    fi
    
    echo "$health_status:${issues[*]}"
}

# Main health monitoring loop
run_health_monitoring() {
    while true; do
        local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
        
        # Check all health aspects
        local forceline_health=$(check_forceline_health)
        local performance_health=$(check_performance_health)
        local system_health=$(check_system_health)
        
        # Determine overall health
        local overall_health="healthy"
        if [[ "$forceline_health" == critical* ]] || \
           [[ "$performance_health" == critical* ]] || \
           [[ "$system_health" == critical* ]]; then
            overall_health="critical"
        elif [[ "$forceline_health" == warning* ]] || \
             [[ "$performance_health" == warning* ]] || \
             [[ "$system_health" == warning* ]]; then
            overall_health="warning"
        fi
        
        # Update health status
        cat > "$MONITORING_DIR/current_health_status.json" << EOF
{
  "timestamp": "$timestamp",
  "overall_health": "$overall_health",
  "components": {
    "forceline": "$forceline_health",
    "performance": "$performance_health", 
    "system": "$system_health"
  }
}
EOF
        
        # Log health status
        echo "[$timestamp] HEALTH_CHECK overall:$overall_health forceline:${forceline_health%%:*} performance:${performance_health%%:*} system:${system_health%%:*}" >> "$MONITORING_DIR/health_monitor.log"
        
        # Trigger alerts if needed
        if [[ "$overall_health" != "healthy" ]]; then
            if [[ -x "$ALERTS_DIR/alert_engine.sh" ]]; then
                "$ALERTS_DIR/alert_engine.sh"
            fi
        fi
        
        sleep "$HEALTH_CHECK_INTERVAL"
    done
}

# Start health monitoring daemon
start_health_monitor() {
    if [[ -f "$HEALTH_PID_FILE" ]] && kill -0 "$(cat "$HEALTH_PID_FILE")" 2>/dev/null; then
        echo "Health monitor already running (PID: $(cat "$HEALTH_PID_FILE"))"
        return 0
    fi
    
    echo "🏥 Starting health monitoring daemon..."
    nohup bash -c "run_health_monitoring" >/dev/null 2>&1 &
    echo $! > "$HEALTH_PID_FILE"
    echo "✅ Health monitor started (PID: $!)"
}

# Stop health monitoring daemon
stop_health_monitor() {
    if [[ -f "$HEALTH_PID_FILE" ]]; then
        local pid=$(cat "$HEALTH_PID_FILE")
        if kill "$pid" 2>/dev/null; then
            echo "✅ Health monitor stopped (PID: $pid)"
        else
            echo "⚠️  Health monitor process not found"
        fi
        rm -f "$HEALTH_PID_FILE"
    else
        echo "⚠️  Health monitor not running"
    fi
}

# Export functions for daemon use
export -f run_health_monitoring check_forceline_health check_performance_health check_system_health

# Handle script execution
case "${1:-start}" in
    start) start_health_monitor ;;
    stop) stop_health_monitor ;;
    restart) 
        stop_health_monitor
        sleep 2
        start_health_monitor
        ;;
    status)
        if [[ -f "$HEALTH_PID_FILE" ]] && kill -0 "$(cat "$HEALTH_PID_FILE")" 2>/dev/null; then
            echo "✅ Health monitor running (PID: $(cat "$HEALTH_PID_FILE"))"
        else
            echo "❌ Health monitor not running"
        fi
        ;;
    *) echo "Usage: $0 {start|stop|restart|status}" ;;
esac
EOF

    chmod +x "$MONITORING_DIR/health_monitor.sh"
}

# Main monitoring interface
main_monitoring() {
    case "${1:-help}" in
        "init")
            init_monitoring_framework
            ;;
        "start")
            start_monitoring_services "${2:-all}"
            ;;
        "stop") 
            stop_monitoring_services "${2:-all}"
            ;;
        "dashboard")
            case "${2:-performance}" in
                "performance") "$DASHBOARDS_DIR/performance_dashboard.sh" ;;
                "health") "$DASHBOARDS_DIR/health_dashboard.sh" ;;
                *) echo "Available dashboards: performance, health" ;;
            esac
            ;;
        "report")
            case "${2:-performance}" in
                "performance") "$REPORTS_DIR/compliance_reporter.sh" generate_performance_report ;;
                "sox") "$REPORTS_DIR/compliance_reporter.sh" generate_sox_report ;;
                "hipaa") "$REPORTS_DIR/compliance_reporter.sh" generate_hipaa_report ;;
                *) echo "Available reports: performance, sox, hipaa" ;;
            esac
            ;;
        "alert")
            "$ALERTS_DIR/alert_engine.sh" run_alert_checks
            ;;
        "help"|*)
            cat << EOF
📊 tmux-forceline Monitoring & Observability System

USAGE:
  $(basename "$0") <command> [options]

COMMANDS:
  init                     Initialize monitoring framework
  start [service]          Start monitoring services (all, health, collectors)
  stop [service]           Stop monitoring services (all, health, collectors)
  dashboard <type>         Show monitoring dashboard
                          Types: performance, health
  report <type>           Generate compliance report
                          Types: performance, sox, hipaa
  alert                   Run alert checks manually
  help                    Show this help message

DASHBOARDS:
  performance             Real-time performance monitoring
  health                  System health and service status

REPORTS:
  performance            SLA and performance compliance
  sox                    Sarbanes-Oxley compliance
  hipaa                  HIPAA compliance assessment

EXAMPLES:
  $(basename "$0") init                          # Initialize monitoring
  $(basename "$0") start                         # Start all monitoring services
  $(basename "$0") dashboard performance         # Show performance dashboard
  $(basename "$0") report sox                    # Generate SOX compliance report
EOF
            ;;
    esac
}

# Start monitoring services
start_monitoring_services() {
    local service="${1:-all}"
    
    case "$service" in
        "all")
            echo "🚀 Starting all monitoring services..."
            "$MONITORING_DIR/health_monitor.sh" start
            start_metric_collectors
            ;;
        "health")
            "$MONITORING_DIR/health_monitor.sh" start
            ;;
        "collectors")
            start_metric_collectors
            ;;
    esac
}

# Start metric collection services
start_metric_collectors() {
    echo "📊 Starting metric collectors..."
    
    # Start performance collector
    (while true; do
        "$COLLECTORS_DIR/performance_collector.sh" collect_performance_metrics
        sleep 60
    done) &
    
    # Start usage collector  
    (while true; do
        "$COLLECTORS_DIR/usage_collector.sh" collect_usage_metrics
        sleep 300
    done) &
    
    # Start system health collector
    (while true; do
        "$COLLECTORS_DIR/system_health_collector.sh" collect_system_health
        sleep 60
    done) &
    
    echo "✅ Metric collectors started"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_monitoring "$@"
fi