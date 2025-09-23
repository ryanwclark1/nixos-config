#!/usr/bin/env bash
# Format Analyzer for tmux-forceline v3.0
# Automated analysis tool to identify native tmux format conversion opportunities
# Based on Tao of Tmux principles for optimal format integration

set -euo pipefail

# Global configuration
readonly ANALYZER_VERSION="3.0"
readonly ANALYSIS_REPORT_DIR="reports"
readonly ANALYSIS_TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# Source centralized utilities
UTILS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$UTILS_DIR/common.sh" ]]; then
    source "$UTILS_DIR/common.sh"
fi

# Module conversion categories based on analysis
declare -A CONVERSION_CATEGORIES=(
    # NATIVE: 100% native format possible (zero shell overhead)
    ["session_info"]="NATIVE"
    ["window_info"]="NATIVE"
    ["pane_info"]="NATIVE"
    ["client_info"]="NATIVE"
    ["tmux_version"]="NATIVE"
    
    # HYBRID: Partial native format possible (mixed approach beneficial)
    ["hostname"]="HYBRID"
    ["datetime"]="HYBRID"
    ["uptime"]="HYBRID"
    ["user_info"]="HYBRID"
    
    # ENHANCED_SHELL: Must remain shell-based but can be optimized
    ["cpu"]="ENHANCED_SHELL"
    ["memory"]="ENHANCED_SHELL"
    ["battery"]="ENHANCED_SHELL"
    ["disk_usage"]="ENHANCED_SHELL"
    ["load"]="ENHANCED_SHELL"
    
    # NETWORK_DEPENDENT: Expensive operations requiring shell
    ["lan_ip"]="NETWORK_DEPENDENT"
    ["wan_ip"]="NETWORK_DEPENDENT"
    ["network"]="NETWORK_DEPENDENT"
    
    # EXTERNAL_API: External service dependencies
    ["weather"]="EXTERNAL_API"
    
    # VERSION_CONTROL: Repository-dependent operations
    ["vcs"]="VERSION_CONTROL"
)

# Native tmux format capabilities
declare -A NATIVE_FORMATS=(
    # Session information
    ["session_name"]="#{session_name}"
    ["session_id"]="#{session_id}"
    ["session_created"]="#{session_created}"
    ["session_last_attached"]="#{session_last_attached}"
    ["session_many_attached"]="#{session_many_attached}"
    ["session_grouped"]="#{session_grouped}"
    
    # Window information
    ["window_index"]="#{window_index}"
    ["window_name"]="#{window_name}"
    ["window_flags"]="#{window_flags}"
    ["window_active"]="#{window_active}"
    ["window_layout"]="#{window_layout}"
    ["window_panes"]="#{window_panes}"
    
    # Pane information
    ["pane_index"]="#{pane_index}"
    ["pane_id"]="#{pane_id}"
    ["pane_title"]="#{pane_title}"
    ["pane_current_path"]="#{pane_current_path}"
    ["pane_current_command"]="#{pane_current_command}"
    ["pane_active"]="#{pane_active}"
    ["pane_width"]="#{pane_width}"
    ["pane_height"]="#{pane_height}"
    
    # Client information
    ["client_name"]="#{client_name}"
    ["client_tty"]="#{client_tty}"
    ["client_width"]="#{client_width}"
    ["client_height"]="#{client_height}"
    
    # Host information (tmux built-in)
    ["host"]="#{host}"
    ["host_short"]="#{host_short}"
    
    # Time and date (tmux built-in strftime)
    ["time"]="#{T:%H:%M}"
    ["date"]="#{T:%Y-%m-%d}"
    ["datetime"]="#{T:%Y-%m-%d %H:%M:%S}"
    ["day_name"]="#{T:%A}"
    ["month_name"]="#{T:%B}"
)

# Performance impact ratings for conversion
declare -A PERFORMANCE_IMPACT=(
    ["NATIVE"]="100"           # 100% performance improvement (zero cost)
    ["HYBRID"]="60"            # 60% improvement (mixed approach)
    ["ENHANCED_SHELL"]="30"    # 30% improvement (optimized shell)
    ["NETWORK_DEPENDENT"]="10" # 10% improvement (caching only)
    ["EXTERNAL_API"]="5"       # 5% improvement (caching only)
    ["VERSION_CONTROL"]="20"   # 20% improvement (smart caching)
)

# Create analysis report directory
init_analysis_environment() {
    local forceline_dir
    forceline_dir=$(get_forceline_dir 2>/dev/null || echo "$(dirname "$UTILS_DIR")")
    local report_dir="$forceline_dir/$ANALYSIS_REPORT_DIR"
    
    mkdir -p "$report_dir" 2>/dev/null || return 1
    echo "$report_dir"
}

# Scan for available modules
discover_modules() {
    local forceline_dir
    forceline_dir=$(get_forceline_dir 2>/dev/null || echo "$(dirname "$UTILS_DIR")")
    
    local modules=()
    
    # Scan modules directory
    if [[ -d "$forceline_dir/modules" ]]; then
        while IFS= read -r -d '' module_dir; do
            local module_name="$(basename "$module_dir")"
            modules+=("$module_name")
        done < <(find "$forceline_dir/modules" -maxdepth 1 -type d -name "*" ! -name "modules" -print0 2>/dev/null)
    fi
    
    # Scan plugins directory
    if [[ -d "$forceline_dir/plugins" ]]; then
        for category in "core" "extended"; do
            local category_dir="$forceline_dir/plugins/$category"
            if [[ -d "$category_dir" ]]; then
                while IFS= read -r -d '' plugin_dir; do
                    local plugin_name="$(basename "$plugin_dir")"
                    modules+=("$plugin_name")
                done < <(find "$category_dir" -maxdepth 1 -type d -name "*" ! -name "$category" -print0 2>/dev/null)
            fi
        done
    fi
    
    # Remove duplicates and sort
    printf '%s\n' "${modules[@]}" | sort -u
}

# Analyze individual module for conversion opportunities
analyze_module() {
    local module="$1"
    local forceline_dir
    forceline_dir=$(get_forceline_dir 2>/dev/null || echo "$(dirname "$UTILS_DIR")")
    
    # Find module files
    local module_files=()
    local possible_locations=(
        "$forceline_dir/modules/$module"
        "$forceline_dir/plugins/core/$module"
        "$forceline_dir/plugins/extended/$module"
    )
    
    for location in "${possible_locations[@]}"; do
        if [[ -d "$location" ]]; then
            while IFS= read -r -d '' file; do
                module_files+=("$file")
            done < <(find "$location" -name "*.sh" -type f -print0 2>/dev/null)
            break
        fi
    done
    
    if [[ ${#module_files[@]} -eq 0 ]]; then
        echo "ERROR: No files found for module: $module" >&2
        return 1
    fi
    
    # Analyze module characteristics
    local conversion_category="${CONVERSION_CATEGORIES[$module]:-ENHANCED_SHELL}"
    local performance_impact="${PERFORMANCE_IMPACT[$conversion_category]:-30}"
    
    # Analyze file contents for conversion opportunities
    local shell_commands=0
    local tmux_references=0
    local external_dependencies=0
    local file_operations=0
    local network_operations=0
    
    for file in "${module_files[@]}"; do
        if [[ -r "$file" ]]; then
            # Count shell command executions
            shell_commands=$((shell_commands + $(grep -c '`\|$(' "$file" 2>/dev/null || echo 0)))
            
            # Count tmux references
            tmux_references=$((tmux_references + $(grep -c 'tmux\|#{}' "$file" 2>/dev/null || echo 0)))
            
            # Count external dependencies
            external_dependencies=$((external_dependencies + $(grep -cE 'curl|wget|ping|dig|nslookup' "$file" 2>/dev/null || echo 0)))
            
            # Count file operations
            file_operations=$((file_operations + $(grep -cE 'cat|read|ls|find|stat' "$file" 2>/dev/null || echo 0)))
            
            # Count network operations
            network_operations=$((network_operations + $(grep -cE 'ifconfig|ip|netstat|ss' "$file" 2>/dev/null || echo 0)))
        fi
    done
    
    # Determine conversion recommendations
    local native_opportunities=()
    local hybrid_opportunities=()
    local optimization_opportunities=()
    
    case "$conversion_category" in
        "NATIVE")
            # Look for native format opportunities
            for format_key in "${!NATIVE_FORMATS[@]}"; do
                if [[ "$module" == *"$format_key"* ]] || [[ "$format_key" == *"$module"* ]]; then
                    native_opportunities+=("${NATIVE_FORMATS[$format_key]}")
                fi
            done
            ;;
        "HYBRID")
            # Look for mixed opportunities
            for format_key in "${!NATIVE_FORMATS[@]}"; do
                if [[ "$module" == *"$format_key"* ]] || [[ "$format_key" == *"$module"* ]]; then
                    hybrid_opportunities+=("${NATIVE_FORMATS[$format_key]}")
                fi
            done
            
            if [[ $shell_commands -gt 0 ]]; then
                optimization_opportunities+=("Optimize $shell_commands shell command(s)")
            fi
            ;;
        *)
            # Shell-based modules - focus on optimization
            if [[ $shell_commands -gt 5 ]]; then
                optimization_opportunities+=("High shell command usage: $shell_commands commands")
            fi
            
            if [[ $external_dependencies -gt 0 ]]; then
                optimization_opportunities+=("External dependencies: $external_dependencies")
            fi
            
            if [[ $network_operations -gt 0 ]]; then
                optimization_opportunities+=("Network operations: $network_operations")
            fi
            ;;
    esac
    
    # Generate module analysis
    cat <<EOF
{
  "module": "$module",
  "conversion_category": "$conversion_category",
  "performance_impact": $performance_impact,
  "analysis": {
    "shell_commands": $shell_commands,
    "tmux_references": $tmux_references,
    "external_dependencies": $external_dependencies,
    "file_operations": $file_operations,
    "network_operations": $network_operations
  },
  "files_analyzed": ${#module_files[@]},
  "native_opportunities": $(printf '%s\n' "${native_opportunities[@]}" | jq -R . | jq -s . 2>/dev/null || echo '[]'),
  "hybrid_opportunities": $(printf '%s\n' "${hybrid_opportunities[@]}" | jq -R . | jq -s . 2>/dev/null || echo '[]'),
  "optimization_opportunities": $(printf '%s\n' "${optimization_opportunities[@]}" | jq -R . | jq -s . 2>/dev/null || echo '[]'),
  "priority": $(calculate_conversion_priority "$conversion_category" "$performance_impact" "$shell_commands"),
  "estimated_effort": "$(estimate_conversion_effort "$conversion_category" "$shell_commands")"
}
EOF
}

# Calculate conversion priority based on impact and complexity
calculate_conversion_priority() {
    local category="$1"
    local impact="$2"
    local complexity="$3"
    
    # Priority scoring: higher impact + lower complexity = higher priority
    local priority_score
    case "$category" in
        "NATIVE") priority_score=$((impact - complexity / 10)) ;;
        "HYBRID") priority_score=$((impact - complexity / 5)) ;;
        *) priority_score=$((impact - complexity / 2)) ;;
    esac
    
    if [[ $priority_score -ge 80 ]]; then
        echo "1"  # High priority
    elif [[ $priority_score -ge 50 ]]; then
        echo "2"  # Medium priority
    else
        echo "3"  # Low priority
    fi
}

# Estimate conversion effort
estimate_conversion_effort() {
    local category="$1"
    local complexity="$2"
    
    case "$category" in
        "NATIVE")
            if [[ $complexity -le 2 ]]; then
                echo "1-2 hours"
            else
                echo "2-4 hours"
            fi
            ;;
        "HYBRID")
            if [[ $complexity -le 5 ]]; then
                echo "4-8 hours"
            else
                echo "1-2 days"
            fi
            ;;
        *)
            if [[ $complexity -le 10 ]]; then
                echo "2-4 hours"
            else
                echo "1-2 days"
            fi
            ;;
    esac
}

# Generate comprehensive analysis report
generate_analysis_report() {
    local report_dir="$1"
    local modules=("${@:2}")
    
    local report_file="$report_dir/format_analysis_$ANALYSIS_TIMESTAMP.json"
    local summary_file="$report_dir/format_analysis_summary_$ANALYSIS_TIMESTAMP.txt"
    
    echo "Analyzing ${#modules[@]} modules for format conversion opportunities..."
    
    # Initialize report
    cat > "$report_file" <<EOF
{
  "metadata": {
    "timestamp": "$(date -Iseconds)",
    "version": "$ANALYZER_VERSION",
    "total_modules": ${#modules[@]},
    "analysis_id": "$ANALYSIS_TIMESTAMP"
  },
  "modules": {},
  "summary": {}
}
EOF
    
    # Analyze each module
    local total_performance_gain=0
    local high_priority_count=0
    local medium_priority_count=0
    local low_priority_count=0
    
    for module in "${modules[@]}"; do
        echo "  Analyzing module: $module"
        
        local module_analysis
        if module_analysis=$(analyze_module "$module" 2>/dev/null); then
            # Add module analysis to report
            local temp_file="${report_file}.tmp"
            jq --arg module "$module" --argjson analysis "$module_analysis" \
                '.modules[$module] = $analysis' \
                "$report_file" > "$temp_file" && mv "$temp_file" "$report_file"
            
            # Update counters
            local impact priority
            impact=$(echo "$module_analysis" | jq -r '.performance_impact')
            priority=$(echo "$module_analysis" | jq -r '.priority')
            
            total_performance_gain=$((total_performance_gain + impact))
            
            case "$priority" in
                "1") high_priority_count=$((high_priority_count + 1)) ;;
                "2") medium_priority_count=$((medium_priority_count + 1)) ;;
                "3") low_priority_count=$((low_priority_count + 1)) ;;
            esac
        else
            echo "    WARNING: Failed to analyze module: $module"
        fi
    done
    
    # Calculate summary statistics
    local avg_performance_gain
    if [[ ${#modules[@]} -gt 0 ]]; then
        avg_performance_gain=$((total_performance_gain / ${#modules[@]}))
    else
        avg_performance_gain=0
    fi
    
    # Add summary to report
    local temp_file="${report_file}.tmp"
    jq --argjson total_gain "$total_performance_gain" \
       --argjson avg_gain "$avg_performance_gain" \
       --argjson high_priority "$high_priority_count" \
       --argjson medium_priority "$medium_priority_count" \
       --argjson low_priority "$low_priority_count" \
       '.summary = {
         "total_performance_gain": $total_gain,
         "average_performance_gain": $avg_gain,
         "priority_distribution": {
           "high": $high_priority,
           "medium": $medium_priority,
           "low": $low_priority
         }
       }' \
       "$report_file" > "$temp_file" && mv "$temp_file" "$report_file"
    
    # Generate human-readable summary
    generate_summary_report "$report_file" "$summary_file"
    
    echo "Analysis complete!"
    echo "Report saved to: $report_file"
    echo "Summary saved to: $summary_file"
}

# Generate human-readable summary report
generate_summary_report() {
    local report_file="$1"
    local summary_file="$2"
    
    cat > "$summary_file" <<EOF
# tmux-forceline Format Analysis Report
Generated: $(date)
Version: $ANALYZER_VERSION

## Executive Summary
$(jq -r '.summary | "Total Performance Gain: \(.total_performance_gain)%\nAverage Performance Gain: \(.average_performance_gain)%\n\nPriority Distribution:\n  High Priority: \(.priority_distribution.high) modules\n  Medium Priority: \(.priority_distribution.medium) modules\n  Low Priority: \(.priority_distribution.low) modules"' "$report_file")

## High Priority Conversions (Immediate Impact)
$(jq -r '.modules | to_entries | map(select(.value.priority == "1")) | sort_by(.value.performance_impact) | reverse | map("- \(.key): \(.value.conversion_category) (\(.value.performance_impact)% improvement, \(.value.estimated_effort))") | join("\n")' "$report_file")

## Medium Priority Conversions (Significant Impact)
$(jq -r '.modules | to_entries | map(select(.value.priority == "2")) | sort_by(.value.performance_impact) | reverse | map("- \(.key): \(.value.conversion_category) (\(.value.performance_impact)% improvement, \(.value.estimated_effort))") | join("\n")' "$report_file")

## Low Priority Conversions (Minor Impact)
$(jq -r '.modules | to_entries | map(select(.value.priority == "3")) | sort_by(.value.performance_impact) | reverse | map("- \(.key): \(.value.conversion_category) (\(.value.performance_impact)% improvement, \(.value.estimated_effort))") | join("\n")' "$report_file")

## Conversion Categories Overview

### NATIVE Format Candidates (100% improvement potential)
$(jq -r '.modules | to_entries | map(select(.value.conversion_category == "NATIVE")) | map("- \(.key)") | join("\n")' "$report_file")

### HYBRID Format Candidates (60% improvement potential)
$(jq -r '.modules | to_entries | map(select(.value.conversion_category == "HYBRID")) | map("- \(.key)") | join("\n")' "$report_file")

### ENHANCED_SHELL Candidates (30% improvement potential)
$(jq -r '.modules | to_entries | map(select(.value.conversion_category == "ENHANCED_SHELL")) | map("- \(.key)") | join("\n")' "$report_file")

## Implementation Recommendations

### Phase 1: Quick Wins (Native Conversions)
$(jq -r '.modules | to_entries | map(select(.value.conversion_category == "NATIVE" and .value.priority == "1")) | map("1. Convert \(.key) to native format (\(.value.estimated_effort))") | join("\n")' "$report_file")

### Phase 2: Hybrid Integration
$(jq -r '.modules | to_entries | map(select(.value.conversion_category == "HYBRID" and (.value.priority == "1" or .value.priority == "2"))) | map("1. Implement hybrid approach for \(.key) (\(.value.estimated_effort))") | join("\n")' "$report_file")

### Phase 3: Shell Optimization
$(jq -r '.modules | to_entries | map(select(.value.conversion_category == "ENHANCED_SHELL" and .value.priority == "1")) | map("1. Optimize shell commands in \(.key) (\(.value.estimated_effort))") | join("\n")' "$report_file")

## Raw Data Location
Detailed analysis data: $report_file
EOF

    echo "Summary report generated successfully"
}

# Show conversion opportunities for specific module
show_module_opportunities() {
    local module="$1"
    
    echo "Analyzing conversion opportunities for module: $module"
    echo "================================================"
    
    local analysis
    if analysis=$(analyze_module "$module"); then
        local category impact priority effort
        category=$(echo "$analysis" | jq -r '.conversion_category')
        impact=$(echo "$analysis" | jq -r '.performance_impact')
        priority=$(echo "$analysis" | jq -r '.priority')
        effort=$(echo "$analysis" | jq -r '.estimated_effort')
        
        echo "Conversion Category: $category"
        echo "Performance Impact: ${impact}%"
        echo "Priority: $priority (1=High, 2=Medium, 3=Low)"
        echo "Estimated Effort: $effort"
        echo ""
        
        # Show opportunities
        local native_count hybrid_count optimization_count
        native_count=$(echo "$analysis" | jq '.native_opportunities | length')
        hybrid_count=$(echo "$analysis" | jq '.hybrid_opportunities | length')
        optimization_count=$(echo "$analysis" | jq '.optimization_opportunities | length')
        
        if [[ $native_count -gt 0 ]]; then
            echo "Native Format Opportunities:"
            echo "$analysis" | jq -r '.native_opportunities[] | "  - " + .'
            echo ""
        fi
        
        if [[ $hybrid_count -gt 0 ]]; then
            echo "Hybrid Format Opportunities:"
            echo "$analysis" | jq -r '.hybrid_opportunities[] | "  - " + .'
            echo ""
        fi
        
        if [[ $optimization_count -gt 0 ]]; then
            echo "Optimization Opportunities:"
            echo "$analysis" | jq -r '.optimization_opportunities[] | "  - " + .'
            echo ""
        fi
        
        # Show technical analysis
        echo "Technical Analysis:"
        echo "$analysis" | jq -r '.analysis | "  Shell Commands: \(.shell_commands)\n  Tmux References: \(.tmux_references)\n  External Dependencies: \(.external_dependencies)\n  File Operations: \(.file_operations)\n  Network Operations: \(.network_operations)"'
        
    else
        echo "ERROR: Failed to analyze module: $module"
        return 1
    fi
}

# Main CLI interface
main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        "analyze")
            local report_dir
            if ! report_dir=$(init_analysis_environment); then
                echo "ERROR: Failed to initialize analysis environment"
                exit 1
            fi
            
            echo "Discovering modules..."
            local modules=()
            while IFS= read -r module; do
                [[ -n "$module" ]] && modules+=("$module")
            done <<< "$(discover_modules)"
            
            if [[ ${#modules[@]} -eq 0 ]]; then
                echo "No modules found for analysis"
                exit 1
            fi
            
            generate_analysis_report "$report_dir" "${modules[@]}"
            ;;
        "module")
            local module="$1"
            if [[ -z "$module" ]]; then
                echo "ERROR: Module name required"
                exit 1
            fi
            show_module_opportunities "$module"
            ;;
        "list")
            echo "Available modules:"
            discover_modules | sed 's/^/  - /'
            ;;
        "categories")
            echo "Conversion Categories:"
            echo ""
            echo "NATIVE (100% improvement): Zero-cost tmux native formats"
            printf '  %s\n' "${!CONVERSION_CATEGORIES[@]}" | while read -r module; do
                if [[ "${CONVERSION_CATEGORIES[$module]}" == "NATIVE" ]]; then
                    echo "  - $module"
                fi
            done
            echo ""
            echo "HYBRID (60% improvement): Mixed native + optimized shell"
            printf '  %s\n' "${!CONVERSION_CATEGORIES[@]}" | while read -r module; do
                if [[ "${CONVERSION_CATEGORIES[$module]}" == "HYBRID" ]]; then
                    echo "  - $module"
                fi
            done
            echo ""
            echo "ENHANCED_SHELL (30% improvement): Optimized shell commands"
            printf '  %s\n' "${!CONVERSION_CATEGORIES[@]}" | while read -r module; do
                if [[ "${CONVERSION_CATEGORIES[$module]}" == "ENHANCED_SHELL" ]]; then
                    echo "  - $module"
                fi
            done
            ;;
        "help"|*)
            cat <<EOF
Format Analyzer for tmux-forceline v3.0

USAGE:
    $0 <command> [arguments]

COMMANDS:
    analyze
        Perform comprehensive analysis of all modules
        
    module <name>
        Show detailed conversion opportunities for specific module
        
    list
        List all available modules for analysis
        
    categories
        Show conversion categories and module classifications
        
    help
        Show this help message

CONVERSION CATEGORIES:
    NATIVE          - 100% native tmux format (zero cost)
    HYBRID          - Mixed native + shell (60% improvement)
    ENHANCED_SHELL  - Optimized shell commands (30% improvement)
    NETWORK_DEPENDENT - Network operations (caching only)
    EXTERNAL_API    - External service calls (caching only)
    VERSION_CONTROL - Repository operations (smart caching)

EXAMPLES:
    $0 analyze                    # Full analysis report
    $0 module hostname           # Analyze hostname module
    $0 categories               # Show categorizations
    $0 list                     # List available modules
EOF
            ;;
    esac
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi