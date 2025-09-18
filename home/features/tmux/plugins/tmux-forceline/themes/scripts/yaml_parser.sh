#!/usr/bin/env bash
# YAML Theme Parser for tmux-forceline
# Converts Base24 YAML theme files to tmux configuration using core POSIX tools

set -euo pipefail

# Function to parse YAML values using core tools
parse_yaml_value() {
    local file="$1"
    local key="$2"
    
    # Simple YAML parsing using grep and awk
    # Handles: key: "value", key: value, key: '#value'
    grep "^[[:space:]]*${key}:" "$file" | \
    awk -F': *' '{print $2}' | \
    sed 's/^["'\'']*//; s/["'\'']*$//; s/[[:space:]]*#.*//' | \
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

# Function to parse palette colors
parse_palette_colors() {
    local file="$1"
    local output_file="$2"
    
    # Use awk to extract all base24 colors from palette section
    awk '
        /^[[:space:]]*palette:[[:space:]]*$/ { in_palette = 1; next }
        /^[a-zA-Z]/ && in_palette { exit }
        in_palette && /^[[:space:]]*base[0-9A-F]+: / {
            # Extract key and value
            match($0, /^[[:space:]]*([^:]+):[[:space:]]*(.*)$/, parts)
            key = parts[1]
            gsub(/^[[:space:]]*/, "", key)
            
            value = parts[2]
            # Remove quotes first
            gsub(/^[[:space:]]*["'\'']/, "", value)
            gsub(/["'\''][[:space:]]*#.*$/, "", value)
            gsub(/["'\''][[:space:]]*$/, "", value)
            # Trim whitespace
            gsub(/^[[:space:]]*/, "", value)
            gsub(/[[:space:]]*$/, "", value)
            
            # Validate hex color format
            if (value ~ /^#[0-9a-fA-F]{6}$/) {
                print "set -ogq @fl_" key " \"" value "\""
            } else {
                print "Warning: Invalid color format for " key ": " value > "/dev/stderr"
            }
        }
    ' "$file" >> "$output_file"
}

# Function to validate YAML theme structure using core tools
validate_theme() {
    local yaml_file="$1"
    
    if [[ ! -f "$yaml_file" ]]; then
        echo "Error: Theme file '$yaml_file' not found" >&2
        return 1
    fi
    
    # Check required top-level fields
    local system name
    system=$(parse_yaml_value "$yaml_file" "system")
    name=$(parse_yaml_value "$yaml_file" "name")
    
    if [[ -z "$system" ]]; then
        echo "Error: Required field 'system' missing from theme file" >&2
        return 1
    fi
    
    if [[ -z "$name" ]]; then
        echo "Error: Required field 'name' missing from theme file" >&2
        return 1
    fi
    
    # Validate system is base24
    if [[ "$system" != "base24" ]]; then
        echo "Error: Only 'base24' color system is supported, found: $system" >&2
        return 1
    fi
    
    # Check if palette section exists
    if ! grep -q "^[[:space:]]*palette:[[:space:]]*$" "$yaml_file"; then
        echo "Error: Required 'palette' section missing from theme file" >&2
        return 1
    fi
    
    # Validate required base24 colors exist
    local required_colors=(
        "base00" "base01" "base02" "base03" "base04" "base05" "base06" "base07"
        "base08" "base09" "base0A" "base0B" "base0C" "base0D" "base0E" "base0F"
        "base10" "base11" "base12" "base13" "base14" "base15" "base16" "base17"
    )
    
    local missing_colors=()
    for color in "${required_colors[@]}"; do
        if ! grep -q "^[[:space:]]*${color}:[[:space:]]" "$yaml_file"; then
            missing_colors+=("$color")
        fi
    done
    
    if [[ ${#missing_colors[@]} -gt 0 ]]; then
        echo "Error: Required Base24 colors missing from palette: ${missing_colors[*]}" >&2
        return 1
    fi
    
    return 0
}

# Function to convert YAML theme to tmux configuration
yaml_to_tmux() {
    local yaml_file="$1"
    local output_file="$2"
    
    # Validate theme first
    if ! validate_theme "$yaml_file"; then
        return 1
    fi
    
    # Extract theme metadata using core tools
    local theme_name theme_author theme_variant
    theme_name=$(parse_yaml_value "$yaml_file" "name")
    theme_author=$(parse_yaml_value "$yaml_file" "author")
    theme_variant=$(parse_yaml_value "$yaml_file" "variant")
    
    # Set defaults if empty
    theme_author=${theme_author:-"Unknown"}
    theme_variant=${theme_variant:-"unknown"}
    
    # Generate tmux configuration
    cat > "$output_file" << EOF
# vim:set ft=tmux:
# Generated from YAML theme: $theme_name
# Author: $theme_author
# Variant: $theme_variant
# Generated at: $(date -Iseconds)
# Base24 Theme System for tmux-forceline

# Base24 Color Palette
EOF
    
    # Convert Base24 palette to tmux variables
    parse_palette_colors "$yaml_file" "$output_file"
    
    # Add semantic color aliases
    cat >> "$output_file" << 'EOF'

# Semantic Color Aliases (Base24 Standard)
set -ogq @fl_bg "#{@fl_base00}"           # Background
set -ogq @fl_fg "#{@fl_base05}"           # Foreground
set -ogq @fl_surface_0 "#{@fl_base01}"    # Surface level 0
set -ogq @fl_surface_1 "#{@fl_base02}"    # Surface level 1
set -ogq @fl_surface_2 "#{@fl_base03}"    # Surface level 2
set -ogq @fl_muted "#{@fl_base04}"        # Muted text
set -ogq @fl_subtle "#{@fl_base06}"       # Subtle text
set -ogq @fl_text "#{@fl_base07}"         # High contrast text

# Standard color semantics
set -ogq @fl_error "#{@fl_base08}"        # Red - Error states
set -ogq @fl_warning "#{@fl_base09}"      # Orange - Warning states
set -ogq @fl_attention "#{@fl_base0A}"    # Yellow - Attention
set -ogq @fl_success "#{@fl_base0B}"      # Green - Success states
set -ogq @fl_info "#{@fl_base0C}"         # Cyan - Information
set -ogq @fl_primary "#{@fl_base0D}"      # Blue - Primary accent
set -ogq @fl_secondary "#{@fl_base0E}"    # Magenta - Secondary accent
set -ogq @fl_accent "#{@fl_base0F}"       # Brown - Accent color

# Extended palette
set -ogq @fl_mantle "#{@fl_base10}"       # Darker background
set -ogq @fl_crust "#{@fl_base11}"        # Darkest background
set -ogq @fl_bright_red "#{@fl_base12}"   # Bright red
set -ogq @fl_bright_yellow "#{@fl_base13}" # Bright yellow
set -ogq @fl_bright_green "#{@fl_base14}" # Bright green
set -ogq @fl_bright_cyan "#{@fl_base15}"  # Bright cyan
set -ogq @fl_bright_blue "#{@fl_base16}"  # Bright blue
set -ogq @fl_bright_purple "#{@fl_base17}" # Bright purple

# Theme metadata
EOF
    echo "set -ogq @fl_theme_name \"$theme_name\"" >> "$output_file"
    echo "set -ogq @fl_theme_author \"$theme_author\"" >> "$output_file"
    echo "set -ogq @fl_theme_variant \"$theme_variant\"" >> "$output_file"
}

# Function to get available YAML themes
list_yaml_themes() {
    local themes_dir="$1"
    
    if [[ ! -d "$themes_dir/yaml" ]]; then
        echo "No YAML themes directory found at: $themes_dir/yaml" >&2
        return 1
    fi
    
    find "$themes_dir/yaml" -name "*.yaml" -type f | while IFS= read -r theme_file; do
        local theme_name display_name
        theme_name=$(basename "$theme_file" .yaml)
        display_name=$(parse_yaml_value "$theme_file" "name")
        display_name=${display_name:-"Unknown Theme"}
        echo "$theme_name:$display_name"
    done
}

# Function to generate tmux config from YAML theme
generate_theme_config() {
    local theme_name="$1"
    local themes_dir="$2"
    local output_dir="$3"
    
    local yaml_file="$themes_dir/yaml/$theme_name.yaml"
    local tmux_file="$output_dir/generated/$theme_name.conf"
    
    # Create output directory if it doesn't exist
    mkdir -p "$(dirname "$tmux_file")"
    
    # Convert YAML to tmux config
    if yaml_to_tmux "$yaml_file" "$tmux_file"; then
        echo "Generated: $tmux_file"
        return 0
    else
        echo "Failed to generate: $tmux_file" >&2
        return 1
    fi
}

# Main execution
main() {
    local action="${1:-}"
    local theme_name="${2:-}"
    local themes_dir="${3:-$(dirname "$0")/../}"
    
    case "$action" in
        "validate")
            if [[ -z "$theme_name" ]]; then
                echo "Usage: $0 validate <yaml_file>" >&2
                exit 1
            fi
            validate_theme "$theme_name"
            ;;
        "convert")
            if [[ $# -lt 3 ]]; then
                echo "Usage: $0 convert <yaml_file> <output_file>" >&2
                exit 1
            fi
            yaml_to_tmux "$theme_name" "$3"
            ;;
        "generate")
            if [[ -z "$theme_name" ]]; then
                echo "Usage: $0 generate <theme_name> [themes_dir]" >&2
                exit 1
            fi
            generate_theme_config "$theme_name" "$themes_dir" "$themes_dir"
            ;;
        "list")
            list_yaml_themes "$themes_dir"
            ;;
        *)
            echo "Usage: $0 {validate|convert|generate|list} [arguments...]" >&2
            echo "  validate <yaml_file>                    - Validate YAML theme structure" >&2
            echo "  convert <yaml_file> <output_file>       - Convert YAML to tmux config" >&2
            echo "  generate <theme_name> [themes_dir]      - Generate tmux config from YAML theme" >&2
            echo "  list [themes_dir]                       - List available YAML themes" >&2
            exit 1
            ;;
    esac
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi