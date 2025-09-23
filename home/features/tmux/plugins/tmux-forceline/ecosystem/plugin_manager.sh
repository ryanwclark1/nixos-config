#!/usr/bin/env bash
# tmux-forceline v3.0 Plugin Ecosystem Manager
# Community plugin discovery, installation, and performance validation

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly FORCELINE_DIR="$(dirname "$SCRIPT_DIR")"
readonly PLUGIN_REGISTRY_URL="https://raw.githubusercontent.com/your-org/tmux-forceline-registry/main/registry.json"
readonly LOCAL_REGISTRY="$SCRIPT_DIR/local_registry.json"
readonly PLUGIN_CACHE_DIR="${HOME}/.cache/tmux-forceline/plugins"
readonly PLUGIN_INSTALL_DIR="$FORCELINE_DIR/plugins/community"
readonly PERFORMANCE_LOG="$PLUGIN_CACHE_DIR/performance.log"

# Performance standards
readonly MAX_MODULE_EXEC_TIME=100    # milliseconds
readonly MAX_MEMORY_USAGE=10         # MB
readonly MAX_CPU_USAGE=5             # percentage

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
        "header")  echo -e "${PURPLE}🔌${NC} ${WHITE}$*${NC}" ;;
    esac
}

# Function: Initialize plugin ecosystem
init_plugin_ecosystem() {
    mkdir -p "$PLUGIN_CACHE_DIR"
    mkdir -p "$PLUGIN_INSTALL_DIR"
    
    # Create local registry if it doesn't exist
    if [[ ! -f "$LOCAL_REGISTRY" ]]; then
        cat > "$LOCAL_REGISTRY" << 'EOF'
{
  "version": "1.0",
  "last_update": 0,
  "plugins": [],
  "installed": {}
}
EOF
    fi
    
    # Create performance log
    if [[ ! -f "$PERFORMANCE_LOG" ]]; then
        echo "timestamp,plugin,module,exec_time_ms,memory_mb,cpu_percent,status" > "$PERFORMANCE_LOG"
    fi
}

# Function: Fetch plugin registry
fetch_plugin_registry() {
    local force_update="${1:-no}"
    
    # Check if update is needed
    local last_update
    last_update=$(jq -r '.last_update' "$LOCAL_REGISTRY" 2>/dev/null || echo "0")
    local current_time
    current_time=$(date +%s)
    local time_diff=$((current_time - last_update))
    
    if [[ "$force_update" != "yes" && $time_diff -lt 3600 ]]; then
        # Skip update if less than 1 hour since last update
        return 0
    fi
    
    print_status "info" "Fetching plugin registry..."
    
    # Download registry
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL "$PLUGIN_REGISTRY_URL" -o "${LOCAL_REGISTRY}.tmp" 2>/dev/null; then
            mv "${LOCAL_REGISTRY}.tmp" "$LOCAL_REGISTRY"
            print_status "success" "Plugin registry updated"
        else
            print_status "warning" "Failed to fetch registry, using local cache"
            rm -f "${LOCAL_REGISTRY}.tmp"
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget -q "$PLUGIN_REGISTRY_URL" -O "${LOCAL_REGISTRY}.tmp" 2>/dev/null; then
            mv "${LOCAL_REGISTRY}.tmp" "$LOCAL_REGISTRY"
            print_status "success" "Plugin registry updated"
        else
            print_status "warning" "Failed to fetch registry, using local cache"
            rm -f "${LOCAL_REGISTRY}.tmp"
        fi
    else
        print_status "warning" "No HTTP client available, using local cache"
    fi
}

# Function: List available plugins
list_available_plugins() {
    local category="${1:-all}"
    
    fetch_plugin_registry
    
    print_status "header" "Available Community Plugins"
    echo
    
    local plugins
    plugins=$(jq -r '.plugins[]' "$LOCAL_REGISTRY" 2>/dev/null || echo "[]")
    
    if [[ "$plugins" == "[]" ]]; then
        print_status "warning" "No plugins found in registry"
        return 1
    fi
    
    # Group plugins by category
    local categories
    categories=$(jq -r '.plugins[] | .category' "$LOCAL_REGISTRY" 2>/dev/null | sort -u)
    
    for cat in $categories; do
        if [[ "$category" != "all" && "$cat" != "$category" ]]; then
            continue
        fi
        
        echo -e "${CYAN}📂 $cat${NC}"
        
        jq -r --arg cat "$cat" '.plugins[] | select(.category == $cat) | "  \(.name) (v\(.version)) - \(.description)\n    Author: \(.author) | Performance: \(.performance_rating)/5 | Downloads: \(.downloads)"' "$LOCAL_REGISTRY" 2>/dev/null
        
        echo
    done
}

# Function: Show plugin details
show_plugin_details() {
    local plugin_name="$1"
    
    fetch_plugin_registry
    
    local plugin_info
    plugin_info=$(jq --arg name "$plugin_name" '.plugins[] | select(.name == $name)' "$LOCAL_REGISTRY" 2>/dev/null)
    
    if [[ -z "$plugin_info" || "$plugin_info" == "null" ]]; then
        print_status "error" "Plugin '$plugin_name' not found"
        return 1
    fi
    
    print_status "header" "Plugin Details: $plugin_name"
    echo
    
    echo "Name: $(echo "$plugin_info" | jq -r '.name')"
    echo "Version: $(echo "$plugin_info" | jq -r '.version')"
    echo "Author: $(echo "$plugin_info" | jq -r '.author')"
    echo "Category: $(echo "$plugin_info" | jq -r '.category')"
    echo "Description: $(echo "$plugin_info" | jq -r '.description')"
    echo "Performance Rating: $(echo "$plugin_info" | jq -r '.performance_rating')/5"
    echo "Downloads: $(echo "$plugin_info" | jq -r '.downloads')"
    echo "Repository: $(echo "$plugin_info" | jq -r '.repository')"
    echo "License: $(echo "$plugin_info" | jq -r '.license')"
    echo
    
    echo "Dependencies:"
    echo "$plugin_info" | jq -r '.dependencies[]? // "  None"' | sed 's/^/  /'
    echo
    
    echo "Variables Provided:"
    echo "$plugin_info" | jq -r '.variables[]? // "  None"' | sed 's/^/  /'
    echo
    
    echo "Configuration Options:"
    echo "$plugin_info" | jq -r '.config_options[]? // "  None"' | sed 's/^/  /'
    echo
    
    # Check if installed
    local installed_version
    installed_version=$(jq -r --arg name "$plugin_name" '.installed[$name].version // "not installed"' "$LOCAL_REGISTRY")
    echo "Installation Status: $installed_version"
}

# Function: Validate plugin performance
validate_plugin_performance() {
    local plugin_path="$1"
    local plugin_name="$2"
    
    print_status "info" "Validating plugin performance: $plugin_name"
    
    local validation_results=""
    local overall_status="PASS"
    
    # Find executable scripts in plugin
    while IFS= read -r -d '' script_file; do
        if [[ -x "$script_file" ]]; then
            local script_name
            script_name=$(basename "$script_file")
            
            print_status "info" "Testing script: $script_name"
            
            # Measure execution time
            local start_time end_time exec_time
            start_time=$(date +%s%3N)
            
            # Run script with timeout
            if timeout 5s "$script_file" >/dev/null 2>&1; then
                end_time=$(date +%s%3N)
                exec_time=$((end_time - start_time))
                
                # Log performance
                local timestamp
                timestamp=$(date '+%Y-%m-%d %H:%M:%S')
                echo "$timestamp,$plugin_name,$script_name,$exec_time,0,0,PASS" >> "$PERFORMANCE_LOG"
                
                if [[ $exec_time -gt $MAX_MODULE_EXEC_TIME ]]; then
                    print_status "warning" "$script_name execution time: ${exec_time}ms (exceeds ${MAX_MODULE_EXEC_TIME}ms limit)"
                    validation_results+="SLOW_EXECUTION($exec_time ms) "
                    overall_status="WARN"
                else
                    print_status "success" "$script_name execution time: ${exec_time}ms"
                fi
            else
                print_status "error" "$script_name failed to execute or timed out"
                validation_results+="EXECUTION_FAILURE "
                overall_status="FAIL"
            fi
        fi
    done < <(find "$plugin_path" -name "*.sh" -print0)
    
    # Validate plugin structure
    if [[ ! -f "$plugin_path/plugin.conf" ]]; then
        print_status "warning" "Missing plugin.conf configuration file"
        validation_results+="MISSING_CONFIG "
        overall_status="WARN"
    fi
    
    if [[ ! -f "$plugin_path/README.md" ]]; then
        print_status "warning" "Missing README.md documentation"
        validation_results+="MISSING_DOCS "
    fi
    
    # Validate tmux integration
    if [[ -f "$plugin_path/plugin.conf" ]]; then
        if ! grep -q "set.*@" "$plugin_path/plugin.conf"; then
            print_status "warning" "Plugin configuration may not follow tmux-forceline patterns"
            validation_results+="INVALID_CONFIG "
            overall_status="WARN"
        fi
    fi
    
    echo "$overall_status:$validation_results"
}

# Function: Install plugin
install_plugin() {
    local plugin_name="$1"
    local force_install="${2:-no}"
    
    fetch_plugin_registry
    
    # Get plugin info
    local plugin_info
    plugin_info=$(jq --arg name "$plugin_name" '.plugins[] | select(.name == $name)' "$LOCAL_REGISTRY" 2>/dev/null)
    
    if [[ -z "$plugin_info" || "$plugin_info" == "null" ]]; then
        print_status "error" "Plugin '$plugin_name' not found in registry"
        return 1
    fi
    
    # Check if already installed
    local installed_version
    installed_version=$(jq -r --arg name "$plugin_name" '.installed[$name].version // ""' "$LOCAL_REGISTRY")
    local plugin_version
    plugin_version=$(echo "$plugin_info" | jq -r '.version')
    
    if [[ -n "$installed_version" && "$force_install" != "yes" ]]; then
        if [[ "$installed_version" == "$plugin_version" ]]; then
            print_status "info" "Plugin '$plugin_name' v$plugin_version is already installed"
            return 0
        else
            print_status "info" "Plugin '$plugin_name' v$installed_version is installed, v$plugin_version available"
            read -p "Upgrade to v$plugin_version? [y/N]: " -r upgrade_choice
            if [[ ! "$upgrade_choice" =~ ^[Yy]$ ]]; then
                return 0
            fi
        fi
    fi
    
    print_status "info" "Installing plugin: $plugin_name v$plugin_version"
    
    # Get download URL
    local download_url
    download_url=$(echo "$plugin_info" | jq -r '.download_url')
    
    local temp_dir
    temp_dir=$(mktemp -d)
    local plugin_install_path="$PLUGIN_INSTALL_DIR/$plugin_name"
    
    # Download and extract plugin
    if [[ "$download_url" =~ \.git$ ]]; then
        # Git repository
        if command -v git >/dev/null 2>&1; then
            if git clone "$download_url" "$temp_dir/$plugin_name" >/dev/null 2>&1; then
                print_status "success" "Downloaded plugin from git repository"
            else
                print_status "error" "Failed to clone git repository"
                rm -rf "$temp_dir"
                return 1
            fi
        else
            print_status "error" "Git not available for repository download"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        # Archive download
        local archive_file="$temp_dir/plugin.tar.gz"
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL "$download_url" -o "$archive_file"
        elif command -v wget >/dev/null 2>&1; then
            wget -q "$download_url" -O "$archive_file"
        else
            print_status "error" "No HTTP client available for download"
            rm -rf "$temp_dir"
            return 1
        fi
        
        # Extract archive
        mkdir -p "$temp_dir/$plugin_name"
        if tar -xzf "$archive_file" -C "$temp_dir/$plugin_name" --strip-components=1 2>/dev/null; then
            print_status "success" "Extracted plugin archive"
        else
            print_status "error" "Failed to extract plugin archive"
            rm -rf "$temp_dir"
            return 1
        fi
    fi
    
    # Validate plugin performance
    local validation_result
    validation_result=$(validate_plugin_performance "$temp_dir/$plugin_name" "$plugin_name")
    local validation_status="${validation_result%%:*}"
    local validation_issues="${validation_result#*:}"
    
    if [[ "$validation_status" == "FAIL" ]]; then
        print_status "error" "Plugin validation failed: $validation_issues"
        print_status "error" "Installation aborted for safety"
        rm -rf "$temp_dir"
        return 1
    elif [[ "$validation_status" == "WARN" ]]; then
        print_status "warning" "Plugin validation warnings: $validation_issues"
        if [[ "$force_install" != "yes" ]]; then
            read -p "Continue installation despite warnings? [y/N]: " -r continue_choice
            if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
                rm -rf "$temp_dir"
                return 1
            fi
        fi
    fi
    
    # Install plugin
    rm -rf "$plugin_install_path"
    mv "$temp_dir/$plugin_name" "$plugin_install_path"
    
    # Make scripts executable
    find "$plugin_install_path" -name "*.sh" -exec chmod +x {} \;
    
    # Update local registry
    local current_time
    current_time=$(date +%s)
    jq --arg name "$plugin_name" \
       --arg version "$plugin_version" \
       --arg time "$current_time" \
       --arg path "$plugin_install_path" \
       '.installed[$name] = {version: $version, install_time: ($time | tonumber), path: $path}' \
       "$LOCAL_REGISTRY" > "${LOCAL_REGISTRY}.tmp" && mv "${LOCAL_REGISTRY}.tmp" "$LOCAL_REGISTRY"
    
    print_status "success" "Plugin '$plugin_name' v$plugin_version installed successfully"
    
    # Show integration instructions
    if [[ -f "$plugin_install_path/plugin.conf" ]]; then
        echo
        print_status "info" "To enable this plugin, add to your tmux.conf:"
        echo "  source $plugin_install_path/plugin.conf"
    fi
    
    rm -rf "$temp_dir"
}

# Function: Uninstall plugin
uninstall_plugin() {
    local plugin_name="$1"
    
    # Check if installed
    local installed_info
    installed_info=$(jq --arg name "$plugin_name" '.installed[$name] // null' "$LOCAL_REGISTRY" 2>/dev/null)
    
    if [[ "$installed_info" == "null" || -z "$installed_info" ]]; then
        print_status "error" "Plugin '$plugin_name' is not installed"
        return 1
    fi
    
    local plugin_path
    plugin_path=$(echo "$installed_info" | jq -r '.path')
    
    print_status "info" "Uninstalling plugin: $plugin_name"
    
    # Remove plugin files
    if [[ -d "$plugin_path" ]]; then
        rm -rf "$plugin_path"
        print_status "success" "Plugin files removed"
    fi
    
    # Update local registry
    jq --arg name "$plugin_name" 'del(.installed[$name])' "$LOCAL_REGISTRY" > "${LOCAL_REGISTRY}.tmp" && mv "${LOCAL_REGISTRY}.tmp" "$LOCAL_REGISTRY"
    
    print_status "success" "Plugin '$plugin_name' uninstalled successfully"
    print_status "info" "Remember to remove plugin references from your tmux.conf"
}

# Function: List installed plugins
list_installed_plugins() {
    print_status "header" "Installed Plugins"
    echo
    
    local installed_plugins
    installed_plugins=$(jq -r '.installed | keys[]' "$LOCAL_REGISTRY" 2>/dev/null)
    
    if [[ -z "$installed_plugins" ]]; then
        print_status "info" "No plugins installed"
        return 0
    fi
    
    for plugin in $installed_plugins; do
        local version install_time path
        version=$(jq -r --arg name "$plugin" '.installed[$name].version' "$LOCAL_REGISTRY")
        install_time=$(jq -r --arg name "$plugin" '.installed[$name].install_time' "$LOCAL_REGISTRY")
        path=$(jq -r --arg name "$plugin" '.installed[$name].path' "$LOCAL_REGISTRY")
        
        local install_date
        install_date=$(date -d "@$install_time" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "Unknown")
        
        echo "  $plugin v$version"
        echo "    Installed: $install_date"
        echo "    Path: $path"
        echo
    done
}

# Function: Update all plugins
update_all_plugins() {
    print_status "info" "Checking for plugin updates..."
    
    fetch_plugin_registry "yes"
    
    local installed_plugins
    installed_plugins=$(jq -r '.installed | keys[]' "$LOCAL_REGISTRY" 2>/dev/null)
    
    if [[ -z "$installed_plugins" ]]; then
        print_status "info" "No plugins installed"
        return 0
    fi
    
    local updates_available=0
    
    for plugin in $installed_plugins; do
        local installed_version available_version
        installed_version=$(jq -r --arg name "$plugin" '.installed[$name].version' "$LOCAL_REGISTRY")
        available_version=$(jq -r --arg name "$plugin" '.plugins[] | select(.name == $name) | .version' "$LOCAL_REGISTRY" 2>/dev/null)
        
        if [[ -n "$available_version" && "$available_version" != "$installed_version" ]]; then
            print_status "info" "Update available for $plugin: v$installed_version → v$available_version"
            updates_available=$((updates_available + 1))
            
            if install_plugin "$plugin" "yes"; then
                print_status "success" "Updated $plugin to v$available_version"
            else
                print_status "error" "Failed to update $plugin"
            fi
        fi
    done
    
    if [[ $updates_available -eq 0 ]]; then
        print_status "success" "All plugins are up to date"
    fi
}

# Function: Show performance statistics
show_performance_stats() {
    if [[ ! -f "$PERFORMANCE_LOG" ]]; then
        print_status "warning" "No performance data available"
        return 1
    fi
    
    print_status "header" "Plugin Performance Statistics"
    echo
    
    # Show recent performance data
    echo "Recent Performance (last 10 runs):"
    tail -n 10 "$PERFORMANCE_LOG" | column -t -s ','
    echo
    
    # Calculate averages
    if command -v awk >/dev/null 2>&1; then
        echo "Performance Summary:"
        awk -F',' 'NR>1 {
            plugin_count[$2]++
            total_time[$2] += $4
            if ($6 == "PASS") pass_count[$2]++
        }
        END {
            for (plugin in plugin_count) {
                avg_time = total_time[plugin] / plugin_count[plugin]
                success_rate = (pass_count[plugin] / plugin_count[plugin]) * 100
                printf "  %s: %.1fms avg, %.0f%% success rate\n", plugin, avg_time, success_rate
            }
        }' "$PERFORMANCE_LOG"
    fi
}

# Function: Main command dispatcher
main() {
    local command="${1:-list}"
    
    # Initialize plugin ecosystem
    init_plugin_ecosystem
    
    case "$command" in
        "list")
            local category="${2:-all}"
            list_available_plugins "$category"
            ;;
        "search")
            local query="$2"
            fetch_plugin_registry
            jq --arg query "$query" '.plugins[] | select(.name | contains($query) or .description | contains($query))' "$LOCAL_REGISTRY"
            ;;
        "show")
            local plugin_name="$2"
            show_plugin_details "$plugin_name"
            ;;
        "install")
            local plugin_name="$2"
            local force="${3:-no}"
            install_plugin "$plugin_name" "$force"
            ;;
        "uninstall")
            local plugin_name="$2"
            uninstall_plugin "$plugin_name"
            ;;
        "installed")
            list_installed_plugins
            ;;
        "update")
            if [[ -n "${2:-}" ]]; then
                install_plugin "$2" "yes"
            else
                update_all_plugins
            fi
            ;;
        "validate")
            local plugin_path="$2"
            local plugin_name="${3:-test-plugin}"
            validate_plugin_performance "$plugin_path" "$plugin_name"
            ;;
        "performance")
            show_performance_stats
            ;;
        "refresh")
            fetch_plugin_registry "yes"
            ;;
        *)
            echo "Usage: $0 {list|search|show|install|uninstall|installed|update|validate|performance|refresh}"
            echo
            echo "Commands:"
            echo "  list [category]           List available plugins"
            echo "  search <query>            Search plugins by name/description"
            echo "  show <plugin>             Show detailed plugin information"
            echo "  install <plugin> [force]  Install plugin"
            echo "  uninstall <plugin>        Uninstall plugin"
            echo "  installed                 List installed plugins"
            echo "  update [plugin]           Update plugin(s)"
            echo "  validate <path> [name]    Validate plugin performance"
            echo "  performance               Show performance statistics"
            echo "  refresh                   Refresh plugin registry"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"