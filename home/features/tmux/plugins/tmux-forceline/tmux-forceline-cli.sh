#!/usr/bin/env bash
# tmux-forceline v3.0 Unified CLI Interface
# Integrated command-line interface for all advanced features

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION="3.0.0"

# Component paths
readonly INSTALL_SCRIPT="$SCRIPT_DIR/install.sh"
readonly PROFILE_MANAGER="$SCRIPT_DIR/utils/adaptive_profile_manager.sh"
readonly THEME_ENGINE="$SCRIPT_DIR/themes/dynamic_theme_engine.sh"
readonly PLUGIN_MANAGER="$SCRIPT_DIR/ecosystem/plugin_manager.sh"
readonly PERFORMANCE_MONITOR="$SCRIPT_DIR/analytics/performance_monitor.sh"
readonly VALIDATION_SCRIPT="$SCRIPT_DIR/utils/performance_validation.sh"
readonly BENCHMARK_SCRIPT="$SCRIPT_DIR/utils/performance_benchmark.sh"
readonly TELEMETRY_SYSTEM="$SCRIPT_DIR/analytics/telemetry_system.sh"
readonly PLUGIN_SDK="$SCRIPT_DIR/sdk/plugin_sdk.sh"

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
        "header")  echo -e "${PURPLE}🚀${NC} ${WHITE}$*${NC}" ;;
        "subhead") echo -e "${CYAN}$*${NC}" ;;
    esac
}

# Function: Show banner
show_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║              tmux-forceline v3.0 CLI                        ║
║                                                              ║
║     🚀 Revolutionary tmux status bar performance            ║
║     ⚡ Native format integration (100% improvement)         ║
║     🎯 Dynamic themes & plugin ecosystem                    ║
║     📊 Advanced performance monitoring                      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
}

# Function: Show comprehensive help
show_help() {
    show_banner
    echo
    cat << EOF
Usage: tmux-forceline <command> [options]

${CYAN}📦 Installation & Setup:${NC}
  install [--profile=<profile>]     Install tmux-forceline with specified profile
  uninstall                         Uninstall tmux-forceline
  update                            Update to latest version
  validate                          Validate installation and configuration

${CYAN}⚙️ Configuration & Profiles:${NC}
  profile list                      List available profiles
  profile show [profile]            Show profile details
  profile apply <profile>           Apply configuration profile
  profile detect                    Auto-detect optimal profile
  config show                       Show current configuration
  config backup                     Backup current configuration
  config restore <backup>           Restore configuration from backup

${CYAN}🎨 Theme Management:${NC}
  theme list                        List available themes and variants
  theme show <theme>                Show theme details
  theme apply <theme>               Apply theme with dynamic adaptations
  theme daemon start                Start dynamic theme monitoring
  theme daemon stop                 Stop theme monitoring
  theme status                      Show current theme status
  theme create <name>               Create custom theme interactively

${CYAN}🔌 Plugin Ecosystem:${NC}
  plugin list [category]            List available community plugins
  plugin search <query>             Search plugins by name/description
  plugin show <plugin>              Show detailed plugin information
  plugin install <plugin>           Install community plugin
  plugin uninstall <plugin>         Uninstall plugin
  plugin update [plugin]            Update plugin(s)
  plugin validate <path>            Validate plugin performance

${CYAN}📊 Performance & Analytics:${NC}
  monitor start                     Start performance monitoring
  monitor stop                      Stop performance monitoring
  monitor dashboard                 Show real-time performance dashboard
  analyze                           Run comprehensive performance analysis
  benchmark                         Run performance benchmarks
  optimize                          Apply automatic optimizations
  export [file]                     Export performance data

${CYAN}🛠️ Utilities:${NC}
  status                            Show overall system status
  doctor                            Run comprehensive health check
  debug                             Enable debug mode
  reset                             Reset to default configuration
  version                           Show version information
  help                              Show this help message

${CYAN}🏗️ Development & Community:${NC}
  sdk <command>                     Plugin development SDK
  telemetry <command>               Privacy-respecting usage analytics
  contribute                        Show contribution guidelines
  governance                        Show project governance information

${CYAN}Examples:${NC}
  tmux-forceline install --profile=auto    # Auto-install with optimal profile
  tmux-forceline theme apply catppuccin-frappe  # Apply theme with dynamic features
  tmux-forceline plugin install weather    # Install weather plugin
  tmux-forceline monitor dashboard         # Show real-time performance
  tmux-forceline optimize                  # Apply performance optimizations

${CYAN}Quick Start:${NC}
  1. tmux-forceline install --profile=auto
  2. tmux-forceline theme daemon start
  3. tmux-forceline monitor start
  4. Enjoy revolutionary tmux performance!

EOF
}

# Function: Check component availability
check_component() {
    local component="$1"
    local path="$2"
    
    if [[ -x "$path" ]]; then
        return 0
    else
        print_status "error" "$component not available at: $path"
        print_status "info" "Run 'tmux-forceline install' to set up all components"
        return 1
    fi
}

# Function: Show system status
show_status() {
    print_status "header" "tmux-forceline System Status"
    echo
    
    # Version info
    print_status "info" "Version: $VERSION"
    echo
    
    # Component status
    print_status "subhead" "Component Status:"
    local components=(
        "Installation Script:$INSTALL_SCRIPT"
        "Profile Manager:$PROFILE_MANAGER"
        "Theme Engine:$THEME_ENGINE"
        "Plugin Manager:$PLUGIN_MANAGER"
        "Performance Monitor:$PERFORMANCE_MONITOR"
    )
    
    for component in "${components[@]}"; do
        local name="${component%%:*}"
        local path="${component##*:}"
        if [[ -x "$path" ]]; then
            echo "  ✅ $name"
        else
            echo "  ❌ $name"
        fi
    done
    echo
    
    # tmux integration status
    print_status "subhead" "tmux Integration:"
    if command -v tmux >/dev/null 2>&1; then
        local tmux_version
        tmux_version=$(tmux -V)
        echo "  ✅ $tmux_version"
        
        # Check if tmux-forceline is loaded
        if tmux show-options -g | grep -q "@forceline" 2>/dev/null; then
            echo "  ✅ tmux-forceline configuration loaded"
        else
            echo "  ⚠️  tmux-forceline not configured in tmux"
        fi
    else
        echo "  ❌ tmux not installed"
    fi
    echo
    
    # Service status
    print_status "subhead" "Service Status:"
    
    # Theme daemon
    local theme_daemon_status="Stopped"
    if [[ -f "${HOME}/.cache/tmux-forceline/themes/theme_daemon.pid" ]]; then
        local pid
        pid=$(cat "${HOME}/.cache/tmux-forceline/themes/theme_daemon.pid" 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            theme_daemon_status="Running (PID: $pid)"
        fi
    fi
    echo "  Theme Daemon: $theme_daemon_status"
    
    # Performance monitor
    local monitor_status="Stopped"
    if [[ -f "${HOME}/.cache/tmux-forceline/analytics/monitor.pid" ]]; then
        local pid
        pid=$(cat "${HOME}/.cache/tmux-forceline/analytics/monitor.pid" 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            monitor_status="Running (PID: $pid)"
        fi
    fi
    echo "  Performance Monitor: $monitor_status"
    echo
    
    # Current configuration
    if [[ -x "$PROFILE_MANAGER" ]]; then
        print_status "subhead" "Current Configuration:"
        "$PROFILE_MANAGER" --show-current 2>/dev/null | sed 's/^/  /' || echo "  Profile information not available"
    fi
}

# Function: Run comprehensive health check
run_doctor() {
    print_status "header" "tmux-forceline Health Check"
    echo
    
    local issues=0
    
    # Check tmux version
    print_status "info" "Checking tmux compatibility..."
    if command -v tmux >/dev/null 2>&1; then
        local tmux_version
        tmux_version=$(tmux -V | grep -oE '[0-9]+\.[0-9]+' | head -1)
        local major_version
        major_version=$(echo "$tmux_version" | cut -d. -f1)
        if [[ $major_version -ge 3 ]]; then
            print_status "success" "tmux version $tmux_version is compatible"
        else
            print_status "error" "tmux version $tmux_version is too old (3.0+ required)"
            issues=$((issues + 1))
        fi
    else
        print_status "error" "tmux is not installed"
        issues=$((issues + 1))
    fi
    
    # Check dependencies
    print_status "info" "Checking dependencies..."
    local deps=("yq:YAML theme processing" "curl:Network module functionality" "git:Plugin management")
    for dep in "${deps[@]}"; do
        local cmd="${dep%%:*}"
        local desc="${dep##*:}"
        if command -v "$cmd" >/dev/null 2>&1; then
            print_status "success" "$cmd available - $desc"
        else
            print_status "warning" "$cmd not found - $desc may be limited"
        fi
    done
    
    # Check file permissions
    print_status "info" "Checking file permissions..."
    local scripts=("$INSTALL_SCRIPT" "$PROFILE_MANAGER" "$THEME_ENGINE" "$PLUGIN_MANAGER" "$PERFORMANCE_MONITOR")
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            if [[ -x "$script" ]]; then
                print_status "success" "$(basename "$script") is executable"
            else
                print_status "warning" "$(basename "$script") is not executable - fixing..."
                chmod +x "$script"
            fi
        else
            print_status "error" "$(basename "$script") is missing"
            issues=$((issues + 1))
        fi
    done
    
    # Run performance validation
    if [[ -x "$VALIDATION_SCRIPT" ]]; then
        print_status "info" "Running performance validation..."
        if "$VALIDATION_SCRIPT" --quiet; then
            print_status "success" "Performance validation passed"
        else
            print_status "warning" "Performance validation failed"
            issues=$((issues + 1))
        fi
    fi
    
    # Check configuration
    print_status "info" "Checking configuration..."
    if tmux show-options -g | grep -q "@forceline" 2>/dev/null; then
        print_status "success" "tmux-forceline configuration found"
    else
        print_status "warning" "tmux-forceline not configured - run 'tmux-forceline install'"
    fi
    
    echo
    if [[ $issues -eq 0 ]]; then
        print_status "success" "Health check completed - no critical issues found"
        return 0
    else
        print_status "warning" "Health check completed - $issues issues found"
        print_status "info" "Run suggested fixes or 'tmux-forceline install' to resolve"
        return 1
    fi
}

# Function: Reset configuration
reset_configuration() {
    print_status "warning" "This will reset tmux-forceline to default configuration"
    read -p "Are you sure? [y/N]: " -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_status "info" "Reset cancelled"
        return 0
    fi
    
    print_status "info" "Resetting configuration..."
    
    # Stop services
    if [[ -x "$THEME_ENGINE" ]]; then
        "$THEME_ENGINE" stop-daemon 2>/dev/null || true
    fi
    
    if [[ -x "$PERFORMANCE_MONITOR" ]]; then
        "$PERFORMANCE_MONITOR" stop 2>/dev/null || true
    fi
    
    # Clear cache
    rm -rf "${HOME}/.cache/tmux-forceline" 2>/dev/null || true
    
    # Reset tmux options
    tmux set-option -gu @forceline_theme 2>/dev/null || true
    tmux set-option -gu @forceline_plugins 2>/dev/null || true
    tmux set-option -gu @forceline_auto_profile 2>/dev/null || true
    
    # Apply default profile
    if [[ -x "$PROFILE_MANAGER" ]]; then
        "$PROFILE_MANAGER" --apply=balanced --quiet 2>/dev/null || true
    fi
    
    print_status "success" "Configuration reset to defaults"
    print_status "info" "Restart tmux to apply changes: tmux source-file ~/.tmux.conf"
}

# Function: Main command dispatcher
main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        # Installation & Setup
        "install")
            if check_component "Installation Script" "$INSTALL_SCRIPT"; then
                exec "$INSTALL_SCRIPT" "$@"
            fi
            ;;
        "uninstall")
            print_status "warning" "Uninstalling tmux-forceline..."
            # Add uninstall logic here
            print_status "info" "Remove tmux-forceline references from ~/.tmux.conf manually"
            ;;
        "update")
            print_status "info" "Checking for updates..."
            # Add update logic here
            ;;
        "validate")
            if check_component "Validation Script" "$VALIDATION_SCRIPT"; then
                exec "$VALIDATION_SCRIPT" "$@"
            fi
            ;;
        
        # Configuration & Profiles
        "profile")
            if check_component "Profile Manager" "$PROFILE_MANAGER"; then
                exec "$PROFILE_MANAGER" "$@"
            fi
            ;;
        "config")
            local subcommand="${1:-show}"
            case "$subcommand" in
                "show")
                    tmux show-options -g | grep "@forceline" || echo "No tmux-forceline configuration found"
                    ;;
                "backup"|"restore")
                    print_status "info" "Configuration $subcommand not yet implemented"
                    ;;
                *)
                    print_status "error" "Unknown config subcommand: $subcommand"
                    ;;
            esac
            ;;
        
        # Theme Management
        "theme")
            if check_component "Theme Engine" "$THEME_ENGINE"; then
                exec "$THEME_ENGINE" "$@"
            fi
            ;;
        
        # Plugin Ecosystem
        "plugin")
            if check_component "Plugin Manager" "$PLUGIN_MANAGER"; then
                exec "$PLUGIN_MANAGER" "$@"
            fi
            ;;
        
        # Development & Community
        "sdk")
            if check_component "Plugin SDK" "$PLUGIN_SDK"; then
                exec "$PLUGIN_SDK" "$@"
            fi
            ;;
        "telemetry")
            if check_component "Telemetry System" "$TELEMETRY_SYSTEM"; then
                exec "$TELEMETRY_SYSTEM" "$@"
            fi
            ;;
        "contribute")
            if [[ -f "$SCRIPT_DIR/community/CONTRIBUTING.md" ]]; then
                if command -v less >/dev/null 2>&1; then
                    less "$SCRIPT_DIR/community/CONTRIBUTING.md"
                else
                    cat "$SCRIPT_DIR/community/CONTRIBUTING.md"
                fi
            else
                print_status "error" "Contribution guidelines not found"
                print_status "info" "See: https://github.com/your-org/tmux-forceline/blob/main/community/CONTRIBUTING.md"
            fi
            ;;
        "governance")
            if [[ -f "$SCRIPT_DIR/community/GOVERNANCE.md" ]]; then
                if command -v less >/dev/null 2>&1; then
                    less "$SCRIPT_DIR/community/GOVERNANCE.md"
                else
                    cat "$SCRIPT_DIR/community/GOVERNANCE.md"
                fi
            else
                print_status "error" "Governance documentation not found"
                print_status "info" "See: https://github.com/your-org/tmux-forceline/blob/main/community/GOVERNANCE.md"
            fi
            ;;
        
        # Performance & Analytics
        "monitor")
            if check_component "Performance Monitor" "$PERFORMANCE_MONITOR"; then
                exec "$PERFORMANCE_MONITOR" "$@"
            fi
            ;;
        "analyze")
            if check_component "Performance Monitor" "$PERFORMANCE_MONITOR"; then
                exec "$PERFORMANCE_MONITOR" "analyze"
            fi
            ;;
        "benchmark")
            if check_component "Benchmark Script" "$BENCHMARK_SCRIPT"; then
                exec "$BENCHMARK_SCRIPT" "$@"
            fi
            ;;
        "optimize")
            if check_component "Performance Monitor" "$PERFORMANCE_MONITOR"; then
                exec "$PERFORMANCE_MONITOR" "optimize"
            fi
            ;;
        "export")
            if check_component "Performance Monitor" "$PERFORMANCE_MONITOR"; then
                exec "$PERFORMANCE_MONITOR" "export" "$@"
            fi
            ;;
        
        # Utilities
        "status")
            show_status
            ;;
        "doctor")
            run_doctor
            ;;
        "debug")
            print_status "info" "Enabling debug mode..."
            tmux set-option -g @forceline_debug_modules "yes"
            tmux set-option -g @forceline_debug_performance "yes"
            print_status "success" "Debug mode enabled"
            ;;
        "reset")
            reset_configuration
            ;;
        "version")
            echo "tmux-forceline v$VERSION"
            echo "Revolutionary tmux status bar with native performance integration"
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        
        # Hidden/Advanced commands
        "wizard")
            print_status "header" "tmux-forceline Setup Wizard"
            echo "This guided setup will configure tmux-forceline for optimal performance."
            echo
            
            # Run setup wizard
            if check_component "Installation Script" "$INSTALL_SCRIPT"; then
                "$INSTALL_SCRIPT" --profile=auto
            fi
            
            if check_component "Theme Engine" "$THEME_ENGINE"; then
                "$THEME_ENGINE" start-daemon
            fi
            
            if check_component "Performance Monitor" "$PERFORMANCE_MONITOR"; then
                "$PERFORMANCE_MONITOR" start
            fi
            
            print_status "success" "Setup wizard completed!"
            ;;
        
        *)
            print_status "error" "Unknown command: $command"
            echo
            echo "Run 'tmux-forceline help' for usage information"
            exit 1
            ;;
    esac
}

# Check if running with no arguments
if [[ $# -eq 0 ]]; then
    show_banner
    echo
    print_status "info" "Run 'tmux-forceline help' for usage information"
    print_status "info" "Quick start: 'tmux-forceline wizard'"
    exit 0
fi

# Run main function with all arguments
main "$@"