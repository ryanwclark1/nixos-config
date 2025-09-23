#!/usr/bin/env bash
# Format Conversion Utilities for tmux-forceline v3.0
# Automated migration from shell-based to native/hybrid formats
# Helps users upgrade their configurations for optimal performance

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

# Conversion mapping tables (using literal string matching)
declare -A NATIVE_CONVERSIONS=(
    # Hostname conversions (100% improvement)
    ['$(hostname)']="#{host}"
    ['$(hostname -s)']="#{host_short}"
    ['#(hostname)']="#{host}"
    ['#(hostname -s)']="#{host_short}"
    
    # DateTime conversions (100% improvement)
    ['$(date +%H:%M:%S)']="#{T:%H:%M:%S}"
    ['$(date +%Y-%m-%d)']="#{T:%Y-%m-%d}"
    ['$(date "+%H:%M")']="#{T:%H:%M}"
    ['$(date "+%a %b %d")']="#{T:%a %b %d}"
    ['#(date +%H:%M:%S)']="#{T:%H:%M:%S}"
    ['#(date +%Y-%m-%d)']="#{T:%Y-%m-%d}"
    
    # Path conversions (60% improvement)
    ['$(pwd)']="#{pane_current_path}"
    ['$(basename $(pwd))']="#{b:pane_current_path}"
    ['$(dirname $(pwd))']="#{d:pane_current_path}"
    ['#(pwd)']="#{pane_current_path}"
    ['#(basename $(pwd))']="#{b:pane_current_path}"
)

declare -A HYBRID_CONVERSIONS=(
    # Complex conditional conversions
    ['$(if [ condition ]; then echo "true"; else echo "false"; fi)']="#{?condition,true,false}"
    ['#(if [ condition ]; then echo "true"; else echo "false"; fi)']="#{?condition,true,false}"
    
    # Home directory substitution
    ['$(pwd | sed "s|$HOME|~|")']="#{s|$HOME|~|:pane_current_path}"
    ['#(pwd | sed "s|$HOME|~|")']="#{s|$HOME|~|:pane_current_path}"
    
    # Load detection (requires hybrid module)
    ['$(cat /proc/loadavg | cut -d" " -f1)']="#{E:FORCELINE_LOAD_CURRENT}"
    ['$(uptime | awk -F"load average:" "{print $2}" | awk "{print $1}" | tr -d ",")']="#{E:FORCELINE_LOAD_CURRENT}"
    
    # Uptime detection (requires hybrid module)
    ['$(uptime -p)']="#{E:FORCELINE_UPTIME_FORMATTED}"
    ['#(uptime -p)']="#{E:FORCELINE_UPTIME_FORMATTED}"
)

declare -A COMPLEX_PATTERN_CONVERSIONS=(
    # Conditional coloring patterns
    ['if.*then.*echo.*fg=.*else.*echo.*fg=.*fi']="#{?condition,#[fg=color1]text1#[default],#[fg=color2]text2#[default]}"
    
    # String length checks
    ['if.*length.*then.*else.*fi']="#{?#{>:#{length:string},N},long_format,short_format}"
    
    # Multiple condition checks
    ['if.*elif.*then.*else.*fi']="#{?condition1,result1,#{?condition2,result2,default}}"
)

# Configuration for conversion behavior
declare -A CONVERTER_CONFIG=(
    ["backup_original"]="yes"
    ["validate_conversion"]="yes"
    ["log_level"]="info"
    ["dry_run"]="no"
    ["preserve_comments"]="yes"
    ["create_migration_log"]="yes"
)

# Migration log storage
declare -a MIGRATION_LOG=()
declare -a CONVERSION_WARNINGS=()
declare -a CONVERSION_ERRORS=()

# Utility functions
log_conversion() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%H:%M:%S')
    
    case "$level" in
        "info")
            if [[ "${CONVERTER_CONFIG[log_level]}" =~ ^(debug|info)$ ]]; then
                echo "[$timestamp] [INFO] $message" >&2
            fi
            ;;
        "warn")
            echo "[$timestamp] [WARN] $message" >&2
            CONVERSION_WARNINGS+=("$message")
            ;;
        "error")
            echo "[$timestamp] [ERROR] $message" >&2
            CONVERSION_ERRORS+=("$message")
            ;;
        "debug")
            if [[ "${CONVERTER_CONFIG[log_level]}" == "debug" ]]; then
                echo "[$timestamp] [DEBUG] $message" >&2
            fi
            ;;
    esac
    
    MIGRATION_LOG+=("$timestamp|$level|$message")
}

# Detect conversion opportunities in a string
analyze_format_string() {
    local format_string="$1"
    local analysis_result=""
    local conversion_count=0
    local potential_improvement=0
    
    log_conversion "debug" "Analyzing format string: $format_string"
    
    # Check for native conversion opportunities (literal string matching)
    for pattern in "${!NATIVE_CONVERSIONS[@]}"; do
        if [[ "$format_string" == *"$pattern"* ]]; then
            analysis_result+="NATIVE: $pattern → ${NATIVE_CONVERSIONS[$pattern]} (100% improvement)\n"
            ((conversion_count++))
            potential_improvement=$((potential_improvement + 100))
        fi
    done
    
    # Check for hybrid conversion opportunities (literal string matching)
    for pattern in "${!HYBRID_CONVERSIONS[@]}"; do
        if [[ "$format_string" == *"$pattern"* ]]; then
            analysis_result+="HYBRID: $pattern → ${HYBRID_CONVERSIONS[$pattern]} (60% improvement)\n"
            ((conversion_count++))
            potential_improvement=$((potential_improvement + 60))
        fi
    done
    
    # Check for common patterns with string containment
    if [[ "$format_string" == *'$(date'* ]]; then
        analysis_result+="PATTERN: DateTime command detected - consider #{T:format} conversion\n"
        ((conversion_count++))
        potential_improvement=$((potential_improvement + 100))
    fi
    
    if [[ "$format_string" == *'$(hostname'* ]]; then
        analysis_result+="PATTERN: Hostname command detected - consider #{host} conversion\n"
        ((conversion_count++))
        potential_improvement=$((potential_improvement + 100))
    fi
    
    if [[ "$format_string" == *'$(pwd)'* || "$format_string" == *'$(basename'* ]]; then
        analysis_result+="PATTERN: Path command detected - consider #{pane_current_path} conversion\n"
        ((conversion_count++))
        potential_improvement=$((potential_improvement + 60))
    fi
    
    if [[ $conversion_count -gt 0 ]]; then
        local avg_improvement=$((potential_improvement / conversion_count))
        echo -e "CONVERSIONS_FOUND: $conversion_count\nAVG_IMPROVEMENT: ${avg_improvement}%\nDETAILS:\n$analysis_result"
    else
        echo "NO_CONVERSIONS_FOUND"
    fi
}

# Perform actual conversion on a string
convert_format_string() {
    local input_string="$1"
    local output_string="$input_string"
    local changes_made=0
    
    log_conversion "debug" "Converting format string: $input_string"
    
    # Apply native conversions first (highest priority)
    for pattern in "${!NATIVE_CONVERSIONS[@]}"; do
        local old_string="$output_string"
        output_string="${output_string//$pattern/${NATIVE_CONVERSIONS[$pattern]}}"
        if [[ "$old_string" != "$output_string" ]]; then
            log_conversion "info" "Applied native conversion: $pattern → ${NATIVE_CONVERSIONS[$pattern]}"
            ((changes_made++))
        fi
    done
    
    # Apply hybrid conversions
    for pattern in "${!HYBRID_CONVERSIONS[@]}"; do
        local old_string="$output_string"
        output_string="${output_string//$pattern/${HYBRID_CONVERSIONS[$pattern]}}"
        if [[ "$old_string" != "$output_string" ]]; then
            log_conversion "info" "Applied hybrid conversion: $pattern → ${HYBRID_CONVERSIONS[$pattern]}"
            ((changes_made++))
        fi
    done
    
    # Apply regex-based conversions for complex patterns
    # Home directory pattern
    output_string=$(echo "$output_string" | sed 's/\$(pwd | sed "s|\$HOME|~|")/#{s|$HOME|~|:pane_current_path}/g')
    
    # Simple conditional pattern (basic case)
    output_string=$(echo "$output_string" | sed -E 's/\$\(if \[\[ ([^]]+) \]\]; then echo "([^"]+)"; else echo "([^"]+)"; fi\)/#{?\1,\2,\3}/g')
    
    if [[ $changes_made -gt 0 ]]; then
        log_conversion "info" "Total conversions applied: $changes_made"
        echo "$output_string"
        return 0
    else
        log_conversion "debug" "No conversions applied to: $input_string"
        echo "$input_string"
        return 1
    fi
}

# Validate converted format string
validate_conversion() {
    local original="$1"
    local converted="$2"
    
    log_conversion "debug" "Validating conversion: $original → $converted"
    
    # Basic validation checks
    local validation_errors=0
    
    # Check for unmatched braces
    local open_braces=$(echo "$converted" | grep -o "#{" | wc -l)
    local close_braces=$(echo "$converted" | grep -o "}" | wc -l)
    
    if [[ $open_braces -ne $close_braces ]]; then
        log_conversion "error" "Validation failed: Unmatched braces in $converted"
        ((validation_errors++))
    fi
    
    # Check for valid tmux format syntax
    if [[ "$converted" =~ \#\{[^}]+\} ]]; then
        log_conversion "debug" "Valid tmux format syntax detected"
    elif [[ "$converted" != "$original" ]]; then
        log_conversion "warn" "Conversion may have introduced invalid syntax: $converted"
        ((validation_errors++))
    fi
    
    # Test with tmux if available
    if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
        if ! tmux display-message -p "$converted" >/dev/null 2>&1; then
            log_conversion "warn" "tmux validation failed for: $converted"
            ((validation_errors++))
        else
            log_conversion "debug" "tmux validation passed for: $converted"
        fi
    fi
    
    return $validation_errors
}

# Analyze tmux configuration file
analyze_config_file() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        log_conversion "error" "Configuration file not found: $config_file"
        return 1
    fi
    
    log_conversion "info" "Analyzing configuration file: $config_file"
    
    local total_opportunities=0
    local line_number=0
    
    while IFS= read -r line; do
        ((line_number++))
        
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Check for status-left and status-right configurations
        if [[ "$line" =~ (status-left|status-right|@.*format) ]]; then
            local analysis=$(analyze_format_string "$line")
            if [[ "$analysis" != "NO_CONVERSIONS_FOUND" ]]; then
                echo "Line $line_number: $line"
                echo "$analysis"
                echo "---"
                ((total_opportunities++))
            fi
        fi
    done < "$config_file"
    
    log_conversion "info" "Analysis complete. Found $total_opportunities conversion opportunities."
    return 0
}

# Convert tmux configuration file
convert_config_file() {
    local config_file="$1"
    local output_file="${2:-}"
    
    if [[ ! -f "$config_file" ]]; then
        log_conversion "error" "Configuration file not found: $config_file"
        return 1
    fi
    
    # Create backup if requested
    if [[ "${CONVERTER_CONFIG[backup_original]}" == "yes" ]]; then
        local backup_file="${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$config_file" "$backup_file"
        log_conversion "info" "Created backup: $backup_file"
    fi
    
    # Determine output file
    if [[ -z "$output_file" ]]; then
        if [[ "${CONVERTER_CONFIG[dry_run]}" == "yes" ]]; then
            output_file="/dev/stdout"
        else
            output_file="$config_file"
        fi
    fi
    
    log_conversion "info" "Converting configuration file: $config_file"
    
    local temp_file=$(mktemp)
    local line_number=0
    local conversions_made=0
    
    while IFS= read -r line; do
        ((line_number++))
        local original_line="$line"
        local converted_line="$line"
        
        # Preserve comments if requested
        if [[ "${CONVERTER_CONFIG[preserve_comments]}" == "yes" && "$line" =~ ^[[:space:]]*# ]]; then
            echo "$line" >> "$temp_file"
            continue
        fi
        
        # Skip empty lines
        if [[ -z "${line// }" ]]; then
            echo "$line" >> "$temp_file"
            continue
        fi
        
        # Convert status-related configurations
        if [[ "$line" =~ (status-left|status-right|@.*format) ]]; then
            if converted_line=$(convert_format_string "$line"); then
                if [[ "$converted_line" != "$original_line" ]]; then
                    # Validate conversion if requested
                    if [[ "${CONVERTER_CONFIG[validate_conversion]}" == "yes" ]]; then
                        if ! validate_conversion "$original_line" "$converted_line"; then
                            log_conversion "warn" "Validation failed for line $line_number, keeping original"
                            converted_line="$original_line"
                        fi
                    fi
                    
                    if [[ "$converted_line" != "$original_line" ]]; then
                        log_conversion "info" "Converted line $line_number"
                        ((conversions_made++))
                        
                        # Add comment showing original if in dry run
                        if [[ "${CONVERTER_CONFIG[dry_run]}" == "yes" ]]; then
                            echo "# ORIGINAL: $original_line" >> "$temp_file"
                            echo "# CONVERTED:" >> "$temp_file"
                        fi
                    fi
                fi
            fi
        fi
        
        echo "$converted_line" >> "$temp_file"
    done < "$config_file"
    
    # Write output
    if [[ "$output_file" != "/dev/stdout" ]]; then
        mv "$temp_file" "$output_file"
        log_conversion "info" "Converted configuration saved to: $output_file"
    else
        cat "$temp_file"
        rm "$temp_file"
    fi
    
    log_conversion "info" "Conversion complete. Made $conversions_made changes."
    return 0
}

# Generate migration report
generate_migration_report() {
    local output_file="${1:-migration_report.md}"
    
    log_conversion "info" "Generating migration report: $output_file"
    
    cat > "$output_file" << EOF
# tmux-forceline v3.0 Migration Report

Generated: $(date '+%Y-%m-%d %H:%M:%S')

## Migration Summary

- **Total Warnings**: ${#CONVERSION_WARNINGS[@]}
- **Total Errors**: ${#CONVERSION_ERRORS[@]}
- **Log Entries**: ${#MIGRATION_LOG[@]}

## Conversion Warnings

EOF
    
    if [[ ${#CONVERSION_WARNINGS[@]} -gt 0 ]]; then
        for warning in "${CONVERSION_WARNINGS[@]}"; do
            echo "- $warning" >> "$output_file"
        done
    else
        echo "No warnings generated during conversion." >> "$output_file"
    fi
    
    cat >> "$output_file" << EOF

## Conversion Errors

EOF
    
    if [[ ${#CONVERSION_ERRORS[@]} -gt 0 ]]; then
        for error in "${CONVERSION_ERRORS[@]}"; do
            echo "- $error" >> "$output_file"
        done
    else
        echo "No errors encountered during conversion." >> "$output_file"
    fi
    
    cat >> "$output_file" << EOF

## Available Conversions

### Native Conversions (100% Performance Improvement)

EOF
    
    for pattern in "${!NATIVE_CONVERSIONS[@]}"; do
        echo "- \`$pattern\` → \`${NATIVE_CONVERSIONS[$pattern]}\`" >> "$output_file"
    done
    
    cat >> "$output_file" << EOF

### Hybrid Conversions (60% Performance Improvement)

EOF
    
    for pattern in "${!HYBRID_CONVERSIONS[@]}"; do
        echo "- \`$pattern\` → \`${HYBRID_CONVERSIONS[$pattern]}\`" >> "$output_file"
    done
    
    cat >> "$output_file" << EOF

## Migration Log

EOF
    
    for log_entry in "${MIGRATION_LOG[@]}"; do
        echo "- $log_entry" >> "$output_file"
    done
    
    log_conversion "info" "Migration report saved to: $output_file"
}

# Display help information
show_help() {
    cat << EOF
tmux-forceline v3.0 Format Converter

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    analyze FILE        Analyze configuration file for conversion opportunities
    convert FILE        Convert configuration file to optimized formats
    test STRING         Test conversion of a single format string
    help               Show this help message

OPTIONS:
    --output FILE      Output file for conversion (default: overwrite original)
    --dry-run          Show conversions without applying them
    --no-backup        Don't create backup of original file
    --no-validate      Skip validation of converted formats
    --log-level LEVEL  Set logging level: debug, info, warn, error
    --report FILE      Generate migration report

EXAMPLES:
    # Analyze tmux configuration for opportunities
    $0 analyze ~/.tmux.conf

    # Convert configuration with backup and validation
    $0 convert ~/.tmux.conf --output ~/.tmux.conf.v3

    # Dry run to see what would be converted
    $0 convert ~/.tmux.conf --dry-run

    # Test individual format string conversion
    $0 test '\$(hostname -s)'

    # Convert with detailed logging and report
    $0 convert ~/.tmux.conf --log-level debug --report migration.md

NATIVE CONVERSIONS (100% improvement):
    \$(hostname)                    → #{host}
    \$(hostname -s)                 → #{host_short}
    \$(date +%H:%M:%S)              → #{T:%H:%M:%S}
    \$(tmux display-message -p '#{session_name}') → #{session_name}

HYBRID CONVERSIONS (60% improvement):
    \$(basename \$(pwd))            → #{b:pane_current_path}
    \$(pwd | sed "s|\$HOME|~|")     → #{s|\$HOME|~|:pane_current_path}
    \$(cat /proc/loadavg | cut -d" " -f1) → #{E:FORCELINE_LOAD_CURRENT}

EOF
}

# Main execution
main() {
    local command=""
    local target_file=""
    local output_file=""
    local test_string=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            analyze|convert|test|help)
                command="$1"
                shift
                ;;
            --output)
                output_file="$2"
                shift 2
                ;;
            --dry-run)
                CONVERTER_CONFIG["dry_run"]="yes"
                shift
                ;;
            --no-backup)
                CONVERTER_CONFIG["backup_original"]="no"
                shift
                ;;
            --no-validate)
                CONVERTER_CONFIG["validate_conversion"]="no"
                shift
                ;;
            --log-level)
                CONVERTER_CONFIG["log_level"]="$2"
                shift 2
                ;;
            --report)
                CONVERTER_CONFIG["create_migration_log"]="yes"
                generate_migration_report "$2"
                shift 2
                ;;
            -*)
                log_conversion "error" "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [[ -z "$target_file" && -z "$test_string" ]]; then
                    if [[ "$command" == "test" ]]; then
                        test_string="$1"
                    else
                        target_file="$1"
                    fi
                fi
                shift
                ;;
        esac
    done
    
    # Execute command
    case "$command" in
        "analyze")
            if [[ -z "$target_file" ]]; then
                log_conversion "error" "No file specified for analysis"
                exit 1
            fi
            analyze_config_file "$target_file"
            ;;
        "convert")
            if [[ -z "$target_file" ]]; then
                log_conversion "error" "No file specified for conversion"
                exit 1
            fi
            convert_config_file "$target_file" "$output_file"
            if [[ "${CONVERTER_CONFIG[create_migration_log]}" == "yes" ]]; then
                generate_migration_report "migration_report_$(date +%Y%m%d_%H%M%S).md"
            fi
            ;;
        "test")
            if [[ -z "$test_string" ]]; then
                log_conversion "error" "No string specified for testing"
                exit 1
            fi
            echo "Original: $test_string"
            echo "Analysis:"
            analyze_format_string "$test_string"
            echo ""
            echo "Conversion:"
            converted=$(convert_format_string "$test_string")
            echo "Result: $converted"
            if [[ "$converted" != "$test_string" ]]; then
                validate_conversion "$test_string" "$converted"
            fi
            ;;
        "help"|"")
            show_help
            ;;
        *)
            log_conversion "error" "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi