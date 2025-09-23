#!/usr/bin/env bash
# tmux-forceline v3.0 Enterprise Configuration Manager
# Centralized configuration management with policy enforcement and compliance reporting

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FORCELINE_DIR="$(dirname "$SCRIPT_DIR")"
readonly ENTERPRISE_DIR="${HOME}/.config/tmux-forceline/enterprise"
readonly POLICY_DIR="$ENTERPRISE_DIR/policies"
readonly DEPLOYMENT_DIR="$ENTERPRISE_DIR/deployments"
readonly AUDIT_DIR="$ENTERPRISE_DIR/audit"
readonly CONFIG_TEMPLATES_DIR="$ENTERPRISE_DIR/templates"

# Enterprise configuration
readonly CONFIG_VERSION="1.0"
readonly COMPLIANCE_STANDARDS=("SOX" "HIPAA" "PCI-DSS" "SOC2" "ISO27001")

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
        "header")  echo -e "${PURPLE}🏢${NC} ${WHITE}$*${NC}" ;;
        "enterprise") echo -e "${CYAN}🔒${NC} $*" ;;
    esac
}

# Function: Initialize enterprise configuration
init_enterprise_config() {
    print_status "info" "Initializing enterprise configuration management..."
    
    # Create directory structure
    mkdir -p "$ENTERPRISE_DIR" "$POLICY_DIR" "$DEPLOYMENT_DIR" "$AUDIT_DIR" "$CONFIG_TEMPLATES_DIR"
    
    # Create master configuration
    if [[ ! -f "$ENTERPRISE_DIR/master.json" ]]; then
        create_master_config
    fi
    
    # Create default policies
    create_default_policies
    
    # Create configuration templates
    create_config_templates
    
    # Initialize audit trail
    init_audit_trail
    
    print_status "success" "Enterprise configuration management initialized"
}

# Function: Create master configuration
create_master_config() {
    cat > "$ENTERPRISE_DIR/master.json" << EOF
{
  "version": "$CONFIG_VERSION",
  "enterprise": {
    "organization": "",
    "administrator": "",
    "deployment_id": "$(openssl rand -hex 8)",
    "created": $(date +%s),
    "last_updated": $(date +%s)
  },
  "compliance": {
    "standards": [],
    "audit_enabled": true,
    "reporting_enabled": true,
    "retention_days": 365
  },
  "security": {
    "policy_enforcement": "strict",
    "plugin_whitelist": [],
    "theme_restrictions": [],
    "telemetry_policy": "opt-in",
    "audit_logging": true
  },
  "performance": {
    "global_limits": {
      "max_execution_time_ms": 100,
      "max_memory_mb": 10,
      "max_update_frequency": 1
    },
    "monitoring_enabled": true,
    "alerting_enabled": false,
    "performance_budgets": {}
  },
  "deployment": {
    "management_mode": "centralized",
    "auto_update": false,
    "rollback_enabled": true,
    "configuration_source": "local"
  },
  "user_permissions": {
    "allow_plugin_install": false,
    "allow_theme_change": true,
    "allow_performance_tuning": false,
    "allow_telemetry_control": true
  }
}
EOF
}

# Function: Create default policies
create_default_policies() {
    # Security policy
    cat > "$POLICY_DIR/security.json" << 'EOF'
{
  "name": "Enterprise Security Policy",
  "version": "1.0",
  "description": "Default security controls for enterprise deployments",
  "rules": {
    "plugin_installation": {
      "enabled": false,
      "whitelist_only": true,
      "require_approval": true,
      "allowed_sources": ["official", "enterprise-approved"]
    },
    "theme_management": {
      "custom_themes": false,
      "approved_themes": ["corporate-dark", "corporate-light", "high-contrast"],
      "dynamic_themes": true
    },
    "telemetry": {
      "collection_mode": "opt-in",
      "data_retention": 30,
      "external_transmission": false,
      "compliance_logging": true
    },
    "configuration": {
      "user_overrides": "limited",
      "local_storage": "encrypted",
      "backup_required": true,
      "change_logging": true
    }
  },
  "enforcement": {
    "violation_action": "block",
    "notification": true,
    "escalation": true,
    "compliance_reporting": true
  }
}
EOF

    # Performance policy
    cat > "$POLICY_DIR/performance.json" << 'EOF'
{
  "name": "Enterprise Performance Policy",
  "version": "1.0",
  "description": "Performance standards and limits for enterprise environments",
  "limits": {
    "execution_time": {
      "warning_threshold_ms": 50,
      "critical_threshold_ms": 100,
      "enforcement": "strict"
    },
    "memory_usage": {
      "warning_threshold_mb": 5,
      "critical_threshold_mb": 10,
      "enforcement": "strict"
    },
    "update_frequency": {
      "minimum_interval_sec": 1,
      "maximum_modules": 15,
      "background_updates": true
    },
    "network_usage": {
      "timeout_sec": 5,
      "retry_attempts": 2,
      "cache_required": true
    }
  },
  "monitoring": {
    "continuous_monitoring": true,
    "performance_alerts": true,
    "degradation_detection": true,
    "automatic_optimization": false
  },
  "compliance": {
    "performance_reporting": true,
    "sla_tracking": true,
    "baseline_maintenance": true
  }
}
EOF

    # Compliance policy
    cat > "$POLICY_DIR/compliance.json" << 'EOF'
{
  "name": "Enterprise Compliance Policy",
  "version": "1.0",
  "description": "Compliance controls for regulated environments",
  "standards": {
    "SOX": {
      "audit_logging": true,
      "change_control": true,
      "access_control": true,
      "data_retention": 2555  // 7 years in days
    },
    "HIPAA": {
      "data_encryption": true,
      "access_logging": true,
      "minimum_necessary": true,
      "data_retention": 2190  // 6 years in days
    },
    "PCI-DSS": {
      "secure_configuration": true,
      "vulnerability_management": true,
      "access_monitoring": true,
      "encryption_required": true
    },
    "SOC2": {
      "security_controls": true,
      "availability_monitoring": true,
      "processing_integrity": true,
      "confidentiality": true
    }
  },
  "reporting": {
    "audit_reports": true,
    "compliance_dashboard": true,
    "exception_reporting": true,
    "automated_evidence": true
  }
}
EOF
}

# Function: Create configuration templates
create_config_templates() {
    # Corporate template
    cat > "$CONFIG_TEMPLATES_DIR/corporate.tmux" << 'EOF'
# tmux-forceline Enterprise Corporate Template
# Optimized for corporate environments with compliance requirements

# Enterprise branding
set -g @forceline_theme "corporate-dark"
set -g @forceline_enterprise_mode "yes"

# Approved modules only
set -g @forceline_plugins "hostname,session,datetime,cpu,memory,load"

# Performance constraints
set -g @forceline_update_interval "2"
set -g @forceline_cache_ttl "30"
set -g @forceline_max_execution_time "50"

# Security settings
set -g @forceline_telemetry_enabled "no"
set -g @forceline_plugin_installation "disabled"
set -g @forceline_audit_logging "yes"

# Corporate styling
set -g @forceline_hostname_format "full"
set -g @forceline_session_show_id "yes"
set -g @forceline_datetime_timezone "UTC"

# Compliance
set -g @forceline_audit_trail "yes"
set -g @forceline_change_logging "yes"
set -g @forceline_compliance_mode "SOX,SOC2"
EOF

    # High-security template
    cat > "$CONFIG_TEMPLATES_DIR/high-security.tmux" << 'EOF'
# tmux-forceline Enterprise High-Security Template
# Maximum security controls for sensitive environments

# Minimal approved theme
set -g @forceline_theme "high-contrast"
set -g @forceline_enterprise_mode "yes"
set -g @forceline_security_mode "maximum"

# Essential modules only
set -g @forceline_plugins "hostname,session,datetime"

# Restrictive performance
set -g @forceline_update_interval "5"
set -g @forceline_cache_ttl "60"
set -g @forceline_max_execution_time "25"

# Security lockdown
set -g @forceline_telemetry_enabled "no"
set -g @forceline_plugin_installation "blocked"
set -g @forceline_theme_changes "blocked"
set -g @forceline_user_overrides "blocked"

# Maximum audit
set -g @forceline_audit_logging "maximum"
set -g @forceline_access_logging "yes"
set -g @forceline_change_detection "yes"
set -g @forceline_compliance_mode "all"
EOF

    # Development template
    cat > "$CONFIG_TEMPLATES_DIR/development.tmux" << 'EOF'
# tmux-forceline Enterprise Development Template
# Balanced security and functionality for development environments

# Development-friendly theme
set -g @forceline_theme "corporate-dark"
set -g @forceline_enterprise_mode "yes"

# Extended modules for development
set -g @forceline_plugins "hostname,session,datetime,cpu,memory,load,vcs,directory"

# Balanced performance
set -g @forceline_update_interval "1"
set -g @forceline_cache_ttl "15"
set -g @forceline_max_execution_time "75"

# Controlled security
set -g @forceline_telemetry_enabled "opt-in"
set -g @forceline_plugin_installation "restricted"
set -g @forceline_theme_changes "limited"

# Development features
set -g @forceline_vcs_enabled "yes"
set -g @forceline_directory_smart_path "yes"
set -g @forceline_performance_monitoring "yes"

# Audit compliance
set -g @forceline_audit_logging "standard"
set -g @forceline_compliance_mode "SOC2"
EOF
}

# Function: Initialize audit trail
init_audit_trail() {
    local audit_file="$AUDIT_DIR/audit.log"
    
    if [[ ! -f "$audit_file" ]]; then
        cat > "$audit_file" << EOF
# tmux-forceline Enterprise Audit Trail
# timestamp|user|action|resource|result|details
$(date '+%Y-%m-%d %H:%M:%S')|$(whoami)|INIT|enterprise_config|SUCCESS|Enterprise configuration management initialized
EOF
    fi
}

# Function: Apply enterprise configuration
apply_enterprise_config() {
    local template="${1:-corporate}"
    local force="${2:-no}"
    
    print_status "info" "Applying enterprise configuration template: $template"
    
    # Check if template exists
    local template_file="$CONFIG_TEMPLATES_DIR/${template}.tmux"
    if [[ ! -f "$template_file" ]]; then
        print_status "error" "Template '$template' not found"
        return 1
    fi
    
    # Validate current user permissions
    if ! validate_user_permissions "configuration_change"; then
        print_status "error" "Insufficient permissions for configuration changes"
        return 1
    fi
    
    # Backup current configuration
    if [[ "$force" != "yes" ]]; then
        backup_current_config
    fi
    
    # Apply template
    local tmux_conf="${HOME}/.tmux.conf"
    
    # Remove existing tmux-forceline configuration
    if [[ -f "$tmux_conf" ]]; then
        grep -v "forceline" "$tmux_conf" > "${tmux_conf}.tmp" || true
        mv "${tmux_conf}.tmp" "$tmux_conf"
    fi
    
    # Append enterprise configuration
    echo "" >> "$tmux_conf"
    echo "# tmux-forceline Enterprise Configuration - Template: $template" >> "$tmux_conf"
    echo "# Applied: $(date)" >> "$tmux_conf"
    cat "$template_file" >> "$tmux_conf"
    
    # Log configuration change
    log_audit_event "CONFIG_APPLY" "template:$template" "SUCCESS" "Enterprise template applied"
    
    print_status "success" "Enterprise configuration applied: $template"
    print_status "info" "Reload tmux to activate: tmux source-file ~/.tmux.conf"
}

# Function: Validate user permissions
validate_user_permissions() {
    local action="$1"
    
    # Load user permissions from master config
    local permissions
    permissions=$(jq -r ".user_permissions // {}" "$ENTERPRISE_DIR/master.json" 2>/dev/null)
    
    case "$action" in
        "plugin_install")
            echo "$permissions" | jq -r '.allow_plugin_install // false' | grep -q "true"
            ;;
        "theme_change")
            echo "$permissions" | jq -r '.allow_theme_change // true' | grep -q "true"
            ;;
        "performance_tuning")
            echo "$permissions" | jq -r '.allow_performance_tuning // false' | grep -q "true"
            ;;
        "configuration_change")
            # Always allow for administrators
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function: Backup current configuration
backup_current_config() {
    local backup_dir="$ENTERPRISE_DIR/backups"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    
    if [[ -f "${HOME}/.tmux.conf" ]]; then
        cp "${HOME}/.tmux.conf" "${backup_dir}/tmux.conf.${timestamp}"
        print_status "info" "Configuration backed up: ${backup_dir}/tmux.conf.${timestamp}"
    fi
    
    # Also backup tmux-forceline specific settings
    if [[ -d "${HOME}/.config/tmux-forceline" ]]; then
        tar -czf "${backup_dir}/tmux-forceline.${timestamp}.tar.gz" \
            -C "${HOME}/.config" tmux-forceline 2>/dev/null || true
    fi
}

# Function: Log audit event
log_audit_event() {
    local action="$1"
    local resource="$2"
    local result="$3"
    local details="$4"
    
    local audit_file="$AUDIT_DIR/audit.log"
    local timestamp user
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    user=$(whoami)
    
    echo "${timestamp}|${user}|${action}|${resource}|${result}|${details}" >> "$audit_file"
}

# Function: Run compliance check
run_compliance_check() {
    local standard="${1:-all}"
    
    print_status "header" "Enterprise Compliance Check"
    echo
    
    # Load compliance requirements
    local compliance_policy
    compliance_policy=$(cat "$POLICY_DIR/compliance.json")
    
    local issues=0
    local checks_run=0
    
    # Check audit logging
    print_status "info" "Checking audit logging compliance..."
    checks_run=$((checks_run + 1))
    if [[ -f "$AUDIT_DIR/audit.log" && -s "$AUDIT_DIR/audit.log" ]]; then
        print_status "success" "Audit logging is active"
    else
        print_status "error" "Audit logging not properly configured"
        issues=$((issues + 1))
    fi
    
    # Check data retention
    print_status "info" "Checking data retention policies..."
    checks_run=$((checks_run + 1))
    local retention_days
    retention_days=$(jq -r '.compliance.retention_days // 365' "$ENTERPRISE_DIR/master.json")
    if [[ $retention_days -ge 365 ]]; then
        print_status "success" "Data retention policy compliant ($retention_days days)"
    else
        print_status "warning" "Data retention may not meet compliance requirements ($retention_days days)"
        issues=$((issues + 1))
    fi
    
    # Check security controls
    print_status "info" "Checking security controls..."
    checks_run=$((checks_run + 1))
    local policy_enforcement
    policy_enforcement=$(jq -r '.security.policy_enforcement // "none"' "$ENTERPRISE_DIR/master.json")
    if [[ "$policy_enforcement" == "strict" ]]; then
        print_status "success" "Security policy enforcement is strict"
    else
        print_status "warning" "Security policy enforcement should be set to 'strict'"
        issues=$((issues + 1))
    fi
    
    # Check performance monitoring
    print_status "info" "Checking performance monitoring..."
    checks_run=$((checks_run + 1))
    local monitoring_enabled
    monitoring_enabled=$(jq -r '.performance.monitoring_enabled // false' "$ENTERPRISE_DIR/master.json")
    if [[ "$monitoring_enabled" == "true" ]]; then
        print_status "success" "Performance monitoring is enabled"
    else
        print_status "warning" "Performance monitoring should be enabled for compliance"
        issues=$((issues + 1))
    fi
    
    # Check plugin controls
    print_status "info" "Checking plugin installation controls..."
    checks_run=$((checks_run + 1))
    local allow_plugin_install
    allow_plugin_install=$(jq -r '.user_permissions.allow_plugin_install // true' "$ENTERPRISE_DIR/master.json")
    if [[ "$allow_plugin_install" == "false" ]]; then
        print_status "success" "Plugin installation is properly restricted"
    else
        print_status "warning" "Plugin installation should be restricted in enterprise environments"
        issues=$((issues + 1))
    fi
    
    echo
    print_status "header" "Compliance Check Summary"
    echo "Checks Run: $checks_run"
    echo "Issues Found: $issues"
    
    if [[ $issues -eq 0 ]]; then
        print_status "success" "All compliance checks passed"
        return 0
    else
        print_status "warning" "$issues compliance issues found"
        return 1
    fi
}

# Function: Generate compliance report
generate_compliance_report() {
    local output_file="${1:-compliance_report_$(date +%Y%m%d_%H%M%S).json}"
    local standard="${2:-all}"
    
    print_status "info" "Generating compliance report..."
    
    # Gather compliance data
    local report_data
    report_data=$(jq -n \
        --arg timestamp "$(date +%s)" \
        --arg standard "$standard" \
        --arg organization "$(jq -r '.enterprise.organization // "Unknown"' "$ENTERPRISE_DIR/master.json")" \
        --slurpfile master "$ENTERPRISE_DIR/master.json" \
        --slurpfile security_policy "$POLICY_DIR/security.json" \
        --slurpfile performance_policy "$POLICY_DIR/performance.json" \
        '{
            report: {
                generated: ($timestamp | tonumber),
                standard: $standard,
                organization: $organization,
                compliance_version: "1.0"
            },
            configuration: $master[0],
            policies: {
                security: $security_policy[0],
                performance: $performance_policy[0]
            },
            audit_summary: {},
            compliance_status: {}
        }')
    
    # Add audit summary
    if [[ -f "$AUDIT_DIR/audit.log" ]]; then
        local audit_count
        audit_count=$(wc -l < "$AUDIT_DIR/audit.log")
        report_data=$(echo "$report_data" | jq --arg count "$audit_count" '.audit_summary.total_events = ($count | tonumber)')
    fi
    
    # Add compliance check results
    local compliance_result=0
    if run_compliance_check "$standard" >/dev/null; then
        compliance_result=1
    fi
    
    report_data=$(echo "$report_data" | jq --arg status "$compliance_result" '.compliance_status.overall_compliant = ($status == "1")')
    
    # Write report
    echo "$report_data" > "$output_file"
    
    print_status "success" "Compliance report generated: $output_file"
}

# Function: List available templates
list_templates() {
    print_status "header" "Available Enterprise Templates"
    echo
    
    for template in "$CONFIG_TEMPLATES_DIR"/*.tmux; do
        if [[ -f "$template" ]]; then
            local name description
            name=$(basename "$template" .tmux)
            description=$(grep "^# " "$template" | head -2 | tail -1 | sed 's/^# //')
            
            echo "📋 $name"
            echo "   $description"
            echo
        fi
    done
}

# Function: Show enterprise status
show_enterprise_status() {
    print_status "header" "Enterprise Configuration Status"
    echo
    
    if [[ ! -f "$ENTERPRISE_DIR/master.json" ]]; then
        print_status "warning" "Enterprise configuration not initialized"
        print_status "info" "Run 'tmux-forceline enterprise init' to initialize"
        return 1
    fi
    
    # Load configuration
    local config
    config=$(cat "$ENTERPRISE_DIR/master.json")
    
    local org deployment_id security_mode
    org=$(echo "$config" | jq -r '.enterprise.organization // "Not configured"')
    deployment_id=$(echo "$config" | jq -r '.enterprise.deployment_id // "Unknown"')
    security_mode=$(echo "$config" | jq -r '.security.policy_enforcement // "none"')
    
    echo "Organization: $org"
    echo "Deployment ID: $deployment_id"
    echo "Security Mode: $security_mode"
    echo
    
    # Show compliance status
    local compliance_standards
    compliance_standards=$(echo "$config" | jq -r '.compliance.standards[]? // empty' | tr '\n' ',' | sed 's/,$//')
    if [[ -n "$compliance_standards" ]]; then
        echo "Compliance Standards: $compliance_standards"
    else
        echo "Compliance Standards: None configured"
    fi
    
    echo
    
    # Show recent audit events
    if [[ -f "$AUDIT_DIR/audit.log" ]]; then
        echo "Recent Audit Events:"
        tail -5 "$AUDIT_DIR/audit.log" | while IFS='|' read -r timestamp user action resource result details; do
            echo "  $timestamp: $action on $resource - $result"
        done
    fi
}

# Function: Main command dispatcher
main() {
    local command="${1:-status}"
    
    case "$command" in
        "init")
            init_enterprise_config
            ;;
        "apply")
            local template="${2:-corporate}"
            local force="${3:-no}"
            apply_enterprise_config "$template" "$force"
            ;;
        "templates")
            list_templates
            ;;
        "compliance")
            local standard="${2:-all}"
            run_compliance_check "$standard"
            ;;
        "report")
            local output="${2:-}"
            local standard="${3:-all}"
            generate_compliance_report "$output" "$standard"
            ;;
        "status")
            show_enterprise_status
            ;;
        "audit")
            if [[ -f "$AUDIT_DIR/audit.log" ]]; then
                tail -20 "$AUDIT_DIR/audit.log"
            else
                print_status "info" "No audit log found"
            fi
            ;;
        *)
            echo "Usage: $0 {init|apply|templates|compliance|report|status|audit}"
            echo
            echo "Commands:"
            echo "  init                      Initialize enterprise configuration"
            echo "  apply <template> [force]  Apply enterprise configuration template"
            echo "  templates                 List available configuration templates"
            echo "  compliance [standard]     Run compliance checks"
            echo "  report [file] [standard]  Generate compliance report"
            echo "  status                    Show enterprise configuration status"
            echo "  audit                     Show recent audit events"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"