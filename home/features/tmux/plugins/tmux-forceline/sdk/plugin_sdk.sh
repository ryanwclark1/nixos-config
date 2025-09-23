#!/usr/bin/env bash
# tmux-forceline v3.0 Plugin Development SDK
# Comprehensive toolkit for creating high-performance tmux-forceline plugins

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FORCELINE_DIR="$(dirname "$SCRIPT_DIR")"
readonly SDK_VERSION="1.0.0"
readonly TEMPLATES_DIR="$SCRIPT_DIR/templates"
readonly EXAMPLES_DIR="$SCRIPT_DIR/examples"
readonly TOOLS_DIR="$SCRIPT_DIR/tools"

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
        "header")  echo -e "${PURPLE}🔧${NC} ${WHITE}$*${NC}" ;;
        "sdk")     echo -e "${CYAN}📦${NC} $*" ;;
    esac
}

# Function: Show SDK banner
show_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║            tmux-forceline Plugin Development SDK             ║
║                                                              ║
║     🔧 Create high-performance tmux plugins                  ║
║     ⚡ Native format integration templates                   ║
║     📊 Performance validation tools                         ║
║     🎨 Theme-aware component system                         ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
}

# Function: Initialize SDK
init_sdk() {
    print_status "info" "Initializing tmux-forceline Plugin SDK..."
    
    # Create SDK directories
    mkdir -p "$TEMPLATES_DIR" "$EXAMPLES_DIR" "$TOOLS_DIR"
    
    # Create templates
    create_plugin_templates
    
    # Create example plugins
    create_example_plugins
    
    # Create development tools
    create_development_tools
    
    print_status "success" "SDK initialized successfully"
}

# Function: Create plugin templates
create_plugin_templates() {
    # Native plugin template
    cat > "$TEMPLATES_DIR/native_plugin_template.conf" << 'EOF'
# vim:set ft=tmux:
# {{PLUGIN_NAME}} Plugin v{{VERSION}}
# Performance: Native format integration

%hidden MODULE_NAME="{{MODULE_NAME}}"

# Plugin metadata
set -g @_fl_plugin_{{MODULE_NAME}}_version "{{VERSION}}"
set -g @_fl_plugin_{{MODULE_NAME}}_description "{{DESCRIPTION}}"
set -g @_fl_plugin_{{MODULE_NAME}}_category "{{CATEGORY}}"
set -g @_fl_plugin_{{MODULE_NAME}}_performance "native"

# Configuration options with defaults
set -ogq "@{{MODULE_NAME}}_enabled" "yes"
set -ogq "@{{MODULE_NAME}}_format" "default"
set -ogq "@{{MODULE_NAME}}_update_interval" "5"

# Native tmux format integration (zero shell overhead)
set -ogq "@{{MODULE_NAME}}_display" "#{{{TMUX_VARIABLE}}}"
set -ogq "@{{MODULE_NAME}}_icon" "{{ICON}} "

# Theme-aware colors
set -ogq "@{{MODULE_NAME}}_text_fg" "#{@fl_fg}"
set -ogq "@{{MODULE_NAME}}_text_bg" "#{@fl_surface_0}"
set -ogq "@{{MODULE_NAME}}_icon_fg" "#{@fl_primary}"
set -ogq "@{{MODULE_NAME}}_accent_fg" "#{@fl_accent}"

# Conditional formatting for status-based colors
set -ogq "@{{MODULE_NAME}}_status_ok_fg" "#{@fl_success}"
set -ogq "@{{MODULE_NAME}}_status_warn_fg" "#{@fl_warning}"
set -ogq "@{{MODULE_NAME}}_status_error_fg" "#{@fl_error}"

# Load universal renderer
source -F "#{d:current_file}/../../utils/status_module.conf"
EOF

    # Hybrid plugin template
    cat > "$TEMPLATES_DIR/hybrid_plugin_template.conf" << 'EOF'
# vim:set ft=tmux:
# {{PLUGIN_NAME}} Plugin v{{VERSION}}
# Performance: Hybrid (cached calculation + native display)

%hidden MODULE_NAME="{{MODULE_NAME}}"

# Plugin metadata
set -g @_fl_plugin_{{MODULE_NAME}}_version "{{VERSION}}"
set -g @_fl_plugin_{{MODULE_NAME}}_description "{{DESCRIPTION}}"
set -g @_fl_plugin_{{MODULE_NAME}}_category "{{CATEGORY}}"
set -g @_fl_plugin_{{MODULE_NAME}}_performance "hybrid"

# Configuration options
set -ogq "@{{MODULE_NAME}}_enabled" "yes"
set -ogq "@{{MODULE_NAME}}_update_interval" "10"
set -ogq "@{{MODULE_NAME}}_cache_ttl" "30"
set -ogq "@{{MODULE_NAME}}_format" "default"

# Environment variables for native display
set -ogq "@{{MODULE_NAME}}_value" "#{E:{{ENV_VARIABLE}}}"
set -ogq "@{{MODULE_NAME}}_status" "#{E:{{ENV_STATUS_VARIABLE}}}"
set -ogq "@{{MODULE_NAME}}_icon" "{{ICON}} "

# Conditional formatting based on status
set -ogq "@{{MODULE_NAME}}_display" "#{?#{E:{{ENV_STATUS_VARIABLE}}},#[fg=#{@fl_success}],#[fg=#{@fl_error}]}#{E:{{ENV_VARIABLE}}}#[default]"

# Theme integration
set -ogq "@{{MODULE_NAME}}_text_fg" "#{@fl_fg}"
set -ogq "@{{MODULE_NAME}}_text_bg" "#{@fl_surface_0}"

# Background script hook (managed by performance monitor)
set-hook -g after-new-session "run-shell '{{SCRIPT_PATH}} update-env'"
set-hook -g after-kill-session "run-shell '{{SCRIPT_PATH}} cleanup'"

# Load universal renderer
source -F "#{d:current_file}/../../utils/status_module.conf"
EOF

    # Script template for hybrid plugins
    cat > "$TEMPLATES_DIR/hybrid_script_template.sh" << 'EOF'
#!/usr/bin/env bash
# {{PLUGIN_NAME}} Background Script
# Updates environment variables for native tmux display

set -euo pipefail

readonly MODULE_NAME="{{MODULE_NAME}}"
readonly CACHE_FILE="${HOME}/.cache/tmux-forceline/{{MODULE_NAME}}.cache"
readonly ENV_PREFIX="{{ENV_PREFIX}}"

# Performance tracking
track_performance() {
    local start_time="$1"
    local end_time="$2"
    local operation="${3:-update}"
    
    if [[ -x "${HOME}/.config/tmux/plugins/tmux-forceline/analytics/performance_monitor.sh" ]]; then
        "${HOME}/.config/tmux/plugins/tmux-forceline/analytics/performance_monitor.sh" capture \
            "$MODULE_NAME" "$operation" "$start_time" "$end_time" 2>/dev/null || true
    fi
}

# Get cached value or compute new one
get_value() {
    local current_time cache_time cache_ttl value
    current_time=$(date +%s)
    cache_ttl=$(tmux show-option -gv @{{MODULE_NAME}}_cache_ttl 2>/dev/null || echo "30")
    
    # Check cache validity
    if [[ -f "$CACHE_FILE" ]]; then
        cache_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo "0")
        if [[ $((current_time - cache_time)) -lt $cache_ttl ]]; then
            cat "$CACHE_FILE"
            return 0
        fi
    fi
    
    # Compute new value
    local start_time end_time
    start_time=$(date +%s%3N)
    
    # {{COMPUTATION_LOGIC}}
    value="placeholder_value"
    
    end_time=$(date +%s%3N)
    track_performance "$start_time" "$end_time" "compute"
    
    # Cache result
    echo "$value" > "$CACHE_FILE"
    echo "$value"
}

# Update tmux environment variables
update_env() {
    local value status
    value=$(get_value)
    
    # Determine status (customize based on your logic)
    if [[ -n "$value" && "$value" != "error" ]]; then
        status="1"  # Success
    else
        status="0"  # Error
        value="N/A"
    fi
    
    # Set environment variables for native tmux display
    tmux set-environment -g "${ENV_PREFIX}_VALUE" "$value" 2>/dev/null || true
    tmux set-environment -g "${ENV_PREFIX}_STATUS" "$status" 2>/dev/null || true
    tmux set-environment -g "${ENV_PREFIX}_UPDATED" "$(date +%s)" 2>/dev/null || true
}

# Cleanup function
cleanup() {
    rm -f "$CACHE_FILE" 2>/dev/null || true
    tmux set-environment -gu "${ENV_PREFIX}_VALUE" 2>/dev/null || true
    tmux set-environment -gu "${ENV_PREFIX}_STATUS" 2>/dev/null || true
    tmux set-environment -gu "${ENV_PREFIX}_UPDATED" 2>/dev/null || true
}

# Main execution
case "${1:-update-env}" in
    "update-env")
        update_env
        ;;
    "cleanup")
        cleanup
        ;;
    "test")
        echo "Testing {{PLUGIN_NAME}} plugin..."
        value=$(get_value)
        echo "Current value: $value"
        ;;
    *)
        echo "Usage: $0 {update-env|cleanup|test}"
        exit 1
        ;;
esac
EOF

    # Plugin manifest template
    cat > "$TEMPLATES_DIR/plugin_manifest_template.json" << 'EOF'
{
  "name": "{{PLUGIN_NAME}}",
  "version": "{{VERSION}}",
  "description": "{{DESCRIPTION}}",
  "author": "{{AUTHOR}}",
  "email": "{{EMAIL}}",
  "category": "{{CATEGORY}}",
  "license": "{{LICENSE}}",
  "repository": "{{REPOSITORY}}",
  "homepage": "{{HOMEPAGE}}",
  "performance_rating": {{PERFORMANCE_RATING}},
  "tmux_min_version": "3.0",
  "dependencies": {{DEPENDENCIES}},
  "variables": {{VARIABLES}},
  "config_options": {{CONFIG_OPTIONS}},
  "tags": {{TAGS}},
  "screenshots": {{SCREENSHOTS}},
  "documentation": {
    "readme": "README.md",
    "examples": "examples/",
    "api": "docs/api.md"
  },
  "testing": {
    "test_script": "test.sh",
    "performance_test": "perf_test.sh",
    "compatibility": ["linux", "macos", "bsd"]
  }
}
EOF

    # README template
    cat > "$TEMPLATES_DIR/README_template.md" << 'EOF'
# {{PLUGIN_NAME}}

{{DESCRIPTION}}

## Features

- 🚀 **High Performance**: {{PERFORMANCE_TYPE}} integration for optimal speed
- 🎨 **Theme Aware**: Automatically adapts to your tmux-forceline theme
- ⚙️ **Configurable**: Extensive customization options
- 🔧 **Cross-Platform**: Works on Linux, macOS, and BSD

## Installation

### Using tmux-forceline Plugin Manager

```bash
tmux-forceline plugin install {{PLUGIN_NAME}}
```

### Manual Installation

```bash
git clone {{REPOSITORY}} ~/.config/tmux/plugins/tmux-forceline/plugins/community/{{PLUGIN_NAME}}
```

## Configuration

Add to your `~/.tmux.conf`:

```tmux
# Enable {{PLUGIN_NAME}}
source ~/.config/tmux/plugins/tmux-forceline/plugins/community/{{PLUGIN_NAME}}/{{PLUGIN_NAME}}.conf

# Configuration options
set -g @{{MODULE_NAME}}_enabled "yes"
set -g @{{MODULE_NAME}}_format "default"
set -g @{{MODULE_NAME}}_update_interval "{{DEFAULT_INTERVAL}}"
```

## Usage

Add to your status line:

```tmux
set -g status-right "#{@{{MODULE_NAME}}_display} | #{datetime_time}"
```

## Variables

| Variable | Description | Example |
|----------|-------------|---------|
{{VARIABLE_TABLE}}

## Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
{{CONFIG_TABLE}}

## Performance

- **Type**: {{PERFORMANCE_TYPE}}
- **Execution Time**: < {{MAX_EXEC_TIME}}ms
- **Memory Usage**: < {{MAX_MEMORY}}MB
- **Update Frequency**: Every {{DEFAULT_INTERVAL}} seconds

## Examples

### Basic Usage

```tmux
set -g status-right "#{@{{MODULE_NAME}}_icon}#{@{{MODULE_NAME}}_value}"
```

### With Status Colors

```tmux
set -g status-right "#{?#{@{{MODULE_NAME}}_status},#[fg=green],#[fg=red]}#{@{{MODULE_NAME}}_value}#[default]"
```

### Custom Format

```tmux
set -g @{{MODULE_NAME}}_format "custom"
set -g status-right "{{CUSTOM_FORMAT_EXAMPLE}}"
```

## Troubleshooting

### Plugin Not Working

1. Verify tmux-forceline is installed and working
2. Check tmux version (3.0+ required)
3. Validate plugin configuration:
   ```bash
   tmux-forceline plugin validate {{PLUGIN_NAME}}
   ```

### Performance Issues

Monitor plugin performance:

```bash
tmux-forceline monitor dashboard
```

### Debug Mode

Enable debug logging:

```bash
tmux set-option -g @forceline_debug_modules "yes"
```

## Development

### Building from Source

```bash
git clone {{REPOSITORY}}
cd {{PLUGIN_NAME}}
./build.sh
```

### Running Tests

```bash
./test.sh
```

### Performance Testing

```bash
./perf_test.sh
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

{{LICENSE}}

## Credits

- Built for [tmux-forceline](https://github.com/your-org/tmux-forceline)
- {{ADDITIONAL_CREDITS}}
EOF

    print_status "success" "Plugin templates created"
}

# Function: Create example plugins
create_example_plugins() {
    mkdir -p "$EXAMPLES_DIR/system-info" "$EXAMPLES_DIR/weather-simple" "$EXAMPLES_DIR/git-status"
    
    # Example 1: System Info (Native)
    cat > "$EXAMPLES_DIR/system-info/system-info.conf" << 'EOF'
# vim:set ft=tmux:
# System Info Plugin - Native Format Example
# Shows kernel and uptime using pure tmux formats

%hidden MODULE_NAME="system_info"

set -g @_fl_plugin_system_info_version "1.0.0"
set -g @_fl_plugin_system_info_description "System information display"
set -g @_fl_plugin_system_info_category "system"

# Configuration
set -ogq "@system_info_enabled" "yes"
set -ogq "@system_info_show_kernel" "yes"
set -ogq "@system_info_show_uptime" "yes"

# Native tmux formats (zero overhead)
set -ogq "@system_info_kernel" "#{?#{@system_info_show_kernel},#{T/s:uname -r}, }"
set -ogq "@system_info_uptime" "#{?#{@system_info_show_uptime},#{E:FORCELINE_UPTIME_FORMATTED}, }"
set -ogq "@system_info_display" "#{@system_info_kernel}#{@system_info_uptime}"

# Theme colors
set -ogq "@system_info_text_fg" "#{@fl_fg}"
set -ogq "@system_info_text_bg" "#{@fl_surface_0}"

source -F "#{d:current_file}/../../utils/status_module.conf"
EOF

    # Example 2: Weather (Hybrid)
    cat > "$EXAMPLES_DIR/weather-simple/weather.conf" << 'EOF'
# vim:set ft=tmux:
# Simple Weather Plugin - Hybrid Format Example
# Cached weather data with native display

%hidden MODULE_NAME="weather"

set -g @_fl_plugin_weather_version "1.0.0"
set -g @_fl_plugin_weather_description "Simple weather display"
set -g @_fl_plugin_weather_category "lifestyle"

# Configuration
set -ogq "@weather_enabled" "yes"
set -ogq "@weather_location" "auto"
set -ogq "@weather_units" "metric"
set -ogq "@weather_cache_ttl" "1800"  # 30 minutes

# Environment variables for display
set -ogq "@weather_temp" "#{E:WEATHER_TEMP}"
set -ogq "@weather_condition" "#{E:WEATHER_CONDITION}"
set -ogq "@weather_icon" "#{E:WEATHER_ICON}"

# Conditional display with status colors
set -ogq "@weather_display" "#{?#{E:WEATHER_TEMP},#{@weather_icon} #{@weather_temp}°#{@weather_condition}, }"

# Theme colors
set -ogq "@weather_text_fg" "#{@fl_fg}"
set -ogq "@weather_icon_fg" "#{@fl_info}"

# Background update hook
set-hook -g after-new-session "run-shell '#{d:current_file}/weather.sh update-env'"

source -F "#{d:current_file}/../../utils/status_module.conf"
EOF

    cat > "$EXAMPLES_DIR/weather-simple/weather.sh" << 'EOF'
#!/usr/bin/env bash
# Simple Weather Plugin Background Script

set -euo pipefail

readonly CACHE_FILE="${HOME}/.cache/tmux-forceline/weather.cache"
readonly API_KEY="demo_key"  # Replace with real API key

get_weather() {
    local location units cache_ttl
    location=$(tmux show-option -gv @weather_location 2>/dev/null || echo "auto")
    units=$(tmux show-option -gv @weather_units 2>/dev/null || echo "metric")
    cache_ttl=$(tmux show-option -gv @weather_cache_ttl 2>/dev/null || echo "1800")
    
    # Check cache
    if [[ -f "$CACHE_FILE" ]]; then
        local cache_age
        cache_age=$(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") ))
        if [[ $cache_age -lt $cache_ttl ]]; then
            cat "$CACHE_FILE"
            return 0
        fi
    fi
    
    # Fetch new data (replace with real API call)
    local weather_data='{"temp": "22", "condition": "Clear", "icon": "☀️"}'
    echo "$weather_data" > "$CACHE_FILE"
    echo "$weather_data"
}

update_env() {
    local weather temp condition icon
    weather=$(get_weather)
    
    if [[ -n "$weather" ]]; then
        temp=$(echo "$weather" | jq -r '.temp // "N/A"')
        condition=$(echo "$weather" | jq -r '.condition // ""')
        icon=$(echo "$weather" | jq -r '.icon // "🌡️"')
        
        tmux set-environment -g "WEATHER_TEMP" "$temp"
        tmux set-environment -g "WEATHER_CONDITION" "$condition"
        tmux set-environment -g "WEATHER_ICON" "$icon"
    fi
}

case "${1:-update-env}" in
    "update-env") update_env ;;
    "cleanup")
        rm -f "$CACHE_FILE"
        tmux set-environment -gu "WEATHER_TEMP"
        tmux set-environment -gu "WEATHER_CONDITION"
        tmux set-environment -gu "WEATHER_ICON"
        ;;
    *) echo "Usage: $0 {update-env|cleanup}" ;;
esac
EOF

    chmod +x "$EXAMPLES_DIR/weather-simple/weather.sh"

    # Example 3: Git Status (Advanced Hybrid)
    cat > "$EXAMPLES_DIR/git-status/git-status.conf" << 'EOF'
# vim:set ft=tmux:
# Git Status Plugin - Advanced Hybrid Example
# Git repository status with branch and change indicators

%hidden MODULE_NAME="git_status"

set -g @_fl_plugin_git_status_version "1.0.0"
set -g @_fl_plugin_git_status_description "Git repository status"
set -g @_fl_plugin_git_status_category "development"

# Configuration
set -ogq "@git_status_enabled" "yes"
set -ogq "@git_status_show_branch" "yes"
set -ogq "@git_status_show_changes" "yes"
set -ogq "@git_status_show_stash" "yes"
set -ogq "@git_status_max_branch_len" "20"

# Git status environment variables
set -ogq "@git_status_branch" "#{E:GIT_BRANCH}"
set -ogq "@git_status_changes" "#{E:GIT_CHANGES}"
set -ogq "@git_status_clean" "#{E:GIT_CLEAN}"

# Icons and formatting
set -ogq "@git_status_branch_icon" " "
set -ogq "@git_status_clean_icon" "✓"
set -ogq "@git_status_dirty_icon" "±"

# Complex conditional display
set -ogq "@git_status_display" "#{?#{E:GIT_BRANCH},#{@git_status_branch_icon}#{E:GIT_BRANCH}#{?#{E:GIT_CLEAN}, #{@git_status_clean_icon}, #{@git_status_dirty_icon}#{E:GIT_CHANGES}}, }"

# Status-based colors
set -ogq "@git_status_branch_fg" "#{@fl_info}"
set -ogq "@git_status_clean_fg" "#{@fl_success}"
set -ogq "@git_status_dirty_fg" "#{@fl_warning}"

# Update hook for directory changes
set-hook -g after-select-pane "run-shell '#{d:current_file}/git-status.sh update-env'"

source -F "#{d:current_file}/../../utils/status_module.conf"
EOF

    print_status "success" "Example plugins created"
}

# Function: Create development tools
create_development_tools() {
    # Plugin generator script
    cat > "$TOOLS_DIR/generate_plugin.sh" << 'EOF'
#!/usr/bin/env bash
# Plugin Generator Tool

set -euo pipefail

readonly TEMPLATES_DIR="$(dirname "$0")/../templates"

generate_plugin() {
    local plugin_name="$1"
    local plugin_type="$2"
    local output_dir="$3"
    
    # Validate inputs
    if [[ ! "$plugin_name" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        echo "Error: Plugin name must be lowercase with hyphens/underscores only" >&2
        return 1
    fi
    
    # Create plugin directory
    mkdir -p "$output_dir"
    
    # Collect information
    echo "Plugin Generator for tmux-forceline"
    echo
    read -p "Plugin description: " description
    read -p "Author name: " author
    read -p "Author email: " email
    read -p "Category (system/development/lifestyle/utility): " category
    read -p "License (MIT/GPL-3.0/Apache-2.0): " license
    
    # Generate variables based on type
    local module_name="${plugin_name//-/_}"
    local env_prefix="${module_name^^}"
    local icon="🔧"
    
    case "$category" in
        "system") icon="💻" ;;
        "development") icon="⚡" ;;
        "lifestyle") icon="🎯" ;;
        "utility") icon="🔧" ;;
    esac
    
    # Template substitution
    local template_file
    case "$plugin_type" in
        "native")
            template_file="$TEMPLATES_DIR/native_plugin_template.conf"
            ;;
        "hybrid")
            template_file="$TEMPLATES_DIR/hybrid_plugin_template.conf"
            ;;
        *)
            echo "Error: Plugin type must be 'native' or 'hybrid'" >&2
            return 1
            ;;
    esac
    
    # Generate main configuration
    sed -e "s/{{PLUGIN_NAME}}/$plugin_name/g" \
        -e "s/{{MODULE_NAME}}/$module_name/g" \
        -e "s/{{VERSION}}/1.0.0/g" \
        -e "s/{{DESCRIPTION}}/$description/g" \
        -e "s/{{CATEGORY}}/$category/g" \
        -e "s/{{ICON}}/$icon/g" \
        -e "s/{{ENV_PREFIX}}/$env_prefix/g" \
        "$template_file" > "$output_dir/${plugin_name}.conf"
    
    # Generate script for hybrid plugins
    if [[ "$plugin_type" == "hybrid" ]]; then
        sed -e "s/{{PLUGIN_NAME}}/$plugin_name/g" \
            -e "s/{{MODULE_NAME}}/$module_name/g" \
            -e "s/{{ENV_PREFIX}}/$env_prefix/g" \
            "$TEMPLATES_DIR/hybrid_script_template.sh" > "$output_dir/${plugin_name}.sh"
        chmod +x "$output_dir/${plugin_name}.sh"
    fi
    
    # Generate manifest
    sed -e "s/{{PLUGIN_NAME}}/$plugin_name/g" \
        -e "s/{{VERSION}}/1.0.0/g" \
        -e "s/{{DESCRIPTION}}/$description/g" \
        -e "s/{{AUTHOR}}/$author/g" \
        -e "s/{{EMAIL}}/$email/g" \
        -e "s/{{CATEGORY}}/$category/g" \
        -e "s/{{LICENSE}}/$license/g" \
        "$TEMPLATES_DIR/plugin_manifest_template.json" > "$output_dir/.plugin-manifest"
    
    # Generate README
    sed -e "s/{{PLUGIN_NAME}}/$plugin_name/g" \
        -e "s/{{MODULE_NAME}}/$module_name/g" \
        -e "s/{{DESCRIPTION}}/$description/g" \
        -e "s/{{PERFORMANCE_TYPE}}/$plugin_type/g" \
        "$TEMPLATES_DIR/README_template.md" > "$output_dir/README.md"
    
    echo
    echo "✅ Plugin '$plugin_name' generated successfully!"
    echo "📁 Location: $output_dir"
    echo
    echo "Next steps:"
    echo "1. Customize the generated files"
    echo "2. Test your plugin: tmux-forceline plugin validate $output_dir"
    echo "3. Install locally: tmux-forceline plugin install $output_dir"
}

# Main execution
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <plugin-name> <type> <output-directory>"
    echo
    echo "Types:"
    echo "  native - Zero-overhead native tmux format integration"
    echo "  hybrid - Cached computation with native display"
    echo
    echo "Example:"
    echo "  $0 my-awesome-plugin hybrid ./my-awesome-plugin"
    exit 1
fi

generate_plugin "$1" "$2" "$3"
EOF

    chmod +x "$TOOLS_DIR/generate_plugin.sh"

    # Performance testing tool
    cat > "$TOOLS_DIR/perf_test.sh" << 'EOF'
#!/usr/bin/env bash
# Plugin Performance Testing Tool

set -euo pipefail

test_plugin_performance() {
    local plugin_dir="$1"
    local iterations="${2:-10}"
    
    echo "Testing plugin performance: $(basename "$plugin_dir")"
    echo "Iterations: $iterations"
    echo
    
    # Find plugin scripts
    local scripts=()
    while IFS= read -r -d '' script; do
        scripts+=("$script")
    done < <(find "$plugin_dir" -name "*.sh" -executable -print0)
    
    if [[ ${#scripts[@]} -eq 0 ]]; then
        echo "No executable scripts found - checking tmux format performance"
        test_tmux_format_performance "$plugin_dir"
        return
    fi
    
    # Test each script
    for script in "${scripts[@]}"; do
        echo "Testing: $(basename "$script")"
        
        local total_time=0
        local max_time=0
        local min_time=999999
        local failures=0
        
        for ((i=1; i<=iterations; i++)); do
            local start_time end_time exec_time
            start_time=$(date +%s%3N)
            
            if timeout 5s "$script" test >/dev/null 2>&1; then
                end_time=$(date +%s%3N)
                exec_time=$((end_time - start_time))
                
                total_time=$((total_time + exec_time))
                if [[ $exec_time -gt $max_time ]]; then max_time=$exec_time; fi
                if [[ $exec_time -lt $min_time ]]; then min_time=$exec_time; fi
            else
                failures=$((failures + 1))
            fi
        done
        
        local avg_time=$((total_time / (iterations - failures)))
        
        echo "  Average: ${avg_time}ms"
        echo "  Min: ${min_time}ms"
        echo "  Max: ${max_time}ms"
        echo "  Failures: $failures/$iterations"
        
        # Performance assessment
        if [[ $avg_time -lt 50 ]]; then
            echo "  Rating: ✅ Excellent"
        elif [[ $avg_time -lt 100 ]]; then
            echo "  Rating: ✅ Good"
        elif [[ $avg_time -lt 200 ]]; then
            echo "  Rating: ⚠️ Acceptable"
        else
            echo "  Rating: ❌ Poor - consider optimization"
        fi
        
        echo
    done
}

test_tmux_format_performance() {
    local plugin_dir="$1"
    
    # Load plugin and test tmux format evaluation
    if [[ -f "$plugin_dir"/*.conf ]]; then
        echo "Testing tmux format performance..."
        
        local start_time end_time exec_time
        start_time=$(date +%s%3N)
        
        # Test tmux format evaluation speed
        tmux new-session -d -s perf-test
        tmux source-file "$plugin_dir"/*.conf
        tmux display-message -t perf-test -p "#{status-right}" >/dev/null
        tmux kill-session -t perf-test
        
        end_time=$(date +%s%3N)
        exec_time=$((end_time - start_time))
        
        echo "  Format evaluation: ${exec_time}ms"
        if [[ $exec_time -lt 10 ]]; then
            echo "  Rating: ✅ Native performance"
        else
            echo "  Rating: ⚠️ Check for shell commands in formats"
        fi
    fi
}

# Main execution
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <plugin-directory> [iterations]"
    exit 1
fi

test_plugin_performance "$1" "${2:-10}"
EOF

    chmod +x "$TOOLS_DIR/perf_test.sh"

    print_status "success" "Development tools created"
}

# Function: Show SDK help
show_sdk_help() {
    show_banner
    echo
    cat << EOF
tmux-forceline Plugin Development SDK v$SDK_VERSION

${CYAN}🚀 Quick Start:${NC}
  1. Create a new plugin: tmux-forceline sdk create
  2. Test performance: tmux-forceline sdk test
  3. Validate plugin: tmux-forceline sdk validate
  4. Publish plugin: tmux-forceline sdk publish

${CYAN}📦 Commands:${NC}
  init                    Initialize SDK in current directory
  create <name> <type>    Create new plugin from template
  test <path>             Run performance tests
  validate <path>         Validate plugin compliance
  examples                Show example plugins
  docs                    Open development documentation

${CYAN}🔧 Plugin Types:${NC}
  native                  Zero-overhead native tmux formats
  hybrid                  Cached computation + native display

${CYAN}📁 SDK Structure:${NC}
  templates/              Plugin templates and boilerplate
  examples/               Complete example plugins
  tools/                  Development and testing tools
  docs/                   Development documentation

${CYAN}⚡ Performance Standards:${NC}
  Execution time: < 100ms
  Memory usage: < 10MB
  Native formats preferred
  Caching for expensive operations

${CYAN}🎨 Theme Integration:${NC}
  Use #{@fl_*} color variables
  Support light/dark variants
  Follow Base24 color specification

${CYAN}💡 Best Practices:${NC}
  - Prefer native tmux formats over shell scripts
  - Use environment variables for hybrid plugins
  - Implement proper error handling
  - Include comprehensive documentation
  - Test across platforms

EOF
}

# Function: Create new plugin
create_new_plugin() {
    local plugin_name="$1"
    local plugin_type="$2"
    local output_dir="${3:-./}"
    
    if [[ ! -x "$TOOLS_DIR/generate_plugin.sh" ]]; then
        print_status "error" "SDK not initialized. Run 'tmux-forceline sdk init' first."
        return 1
    fi
    
    "$TOOLS_DIR/generate_plugin.sh" "$plugin_name" "$plugin_type" "$output_dir/$plugin_name"
}

# Function: Test plugin
test_plugin() {
    local plugin_path="$1"
    local iterations="${2:-10}"
    
    if [[ ! -x "$TOOLS_DIR/perf_test.sh" ]]; then
        print_status "error" "SDK not initialized. Run 'tmux-forceline sdk init' first."
        return 1
    fi
    
    "$TOOLS_DIR/perf_test.sh" "$plugin_path" "$iterations"
}

# Function: Show examples
show_examples() {
    print_status "header" "Example Plugins"
    echo
    
    if [[ ! -d "$EXAMPLES_DIR" ]]; then
        print_status "error" "SDK not initialized. Run 'tmux-forceline sdk init' first."
        return 1
    fi
    
    for example in "$EXAMPLES_DIR"/*; do
        if [[ -d "$example" ]]; then
            local name description
            name=$(basename "$example")
            description=$(grep -h "description" "$example"/*.conf 2>/dev/null | head -1 | cut -d'"' -f4 || echo "No description")
            
            echo "📦 $name"
            echo "   $description"
            echo "   Path: $example"
            echo
        fi
    done
    
    print_status "info" "Copy examples to start development:"
    echo "  cp -r $EXAMPLES_DIR/system-info ./my-plugin"
}

# Function: Validate plugin
validate_plugin() {
    local plugin_path="$1"
    
    if [[ -x "$FORCELINE_DIR/ecosystem/plugin_manager.sh" ]]; then
        "$FORCELINE_DIR/ecosystem/plugin_manager.sh" validate "$plugin_path"
    else
        print_status "error" "Plugin validation tool not available"
        return 1
    fi
}

# Function: Main command dispatcher
main() {
    local command="${1:-help}"
    
    case "$command" in
        "init")
            init_sdk
            ;;
        "create")
            local name="$2"
            local type="$3"
            local output="${4:-./}"
            create_new_plugin "$name" "$type" "$output"
            ;;
        "test")
            local path="$2"
            local iterations="${3:-10}"
            test_plugin "$path" "$iterations"
            ;;
        "validate")
            local path="$2"
            validate_plugin "$path"
            ;;
        "examples")
            show_examples
            ;;
        "help"|"-h"|"--help")
            show_sdk_help
            ;;
        *)
            echo "Usage: $0 {init|create|test|validate|examples|help}"
            echo "Run '$0 help' for detailed information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"