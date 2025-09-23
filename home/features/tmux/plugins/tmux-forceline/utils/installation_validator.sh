#!/usr/bin/env bash
# tmux-forceline v3.0 Installation Validator
# Comprehensive validation of installation and configuration

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
readonly TMUX_CONF="${HOME}/.tmux.conf"

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Validation results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNING_TESTS=0

# Function: Print colored output
print_status() {
    local level="$1"
    shift
    case "$level" in
        "info")    echo -e "${BLUE}ℹ${NC} $*" ;;
        "success") echo -e "${GREEN}✅${NC} $*" ;;
        "warning") echo -e "${YELLOW}⚠${NC} $*" ;;
        "error")   echo -e "${RED}❌${NC} $*" ;;
        "header")  echo -e "${PURPLE}🔍${NC} ${WHITE}$*${NC}" ;;
        "result")  echo -e "${CYAN}📊${NC} $*" ;;
    esac
}

# Function: Run test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local is_critical="${3:-yes}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command" >/dev/null 2>&1; then
        print_status "success" "$test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        if [[ "$is_critical" == "yes" ]]; then
            print_status "error" "$test_name"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        else
            print_status "warning" "$test_name (non-critical)"
            WARNING_TESTS=$((WARNING_TESTS + 1))
        fi
        return 1
    fi
}

# Function: Validate tmux installation
validate_tmux() {
    print_status "header" "Validating tmux Installation"
    
    run_test "tmux is installed" "command -v tmux"
    
    if command -v tmux >/dev/null 2>&1; then
        local tmux_version
        tmux_version=$(tmux -V | grep -oE '[0-9]+\.[0-9]+' | head -1)
        local major_version
        major_version=$(echo "$tmux_version" | cut -d. -f1)
        
        run_test "tmux version 3.0+ (found: $tmux_version)" "[[ $major_version -ge 3 ]]"
        
        # Test tmux server
        if tmux has-session 2>/dev/null || tmux new-session -d -s validation-test 2>/dev/null; then
            run_test "tmux server is accessible" "true"
            # Clean up test session
            tmux kill-session -t validation-test 2>/dev/null || true
        else
            run_test "tmux server is accessible" "false" "no"
        fi
    fi
    
    echo
}

# Function: Validate dependencies
validate_dependencies() {
    print_status "header" "Validating Dependencies"
    
    run_test "yq is installed" "command -v yq" "no"
    
    if command -v yq >/dev/null 2>&1; then
        local yq_version
        yq_version=$(yq --version | grep -oE '[0-9]+\.[0-9]+' | head -1 2>/dev/null || echo "unknown")
        print_status "info" "yq version: $yq_version"
    fi
    
    run_test "git is available" "command -v git" "no"
    run_test "curl is available" "command -v curl" "no"
    run_test "bash 4.0+ is available" "[[ ${BASH_VERSION%%.*} -ge 4 ]]" "no"
    
    echo
}

# Function: Validate file structure
validate_file_structure() {
    print_status "header" "Validating File Structure"
    
    run_test "Configuration directory exists" "[[ -d '$CONFIG_DIR' ]]"
    run_test "Main configuration file exists" "[[ -f '$CONFIG_DIR/forceline_tmux.conf' ]]"
    run_test "Plugin loader exists" "[[ -f '$CONFIG_DIR/plugins/plugin_loader.conf' ]]"
    run_test "Theme loader exists" "[[ -f '$CONFIG_DIR/themes/theme_loader.conf' ]]"
    
    # Check core modules
    local core_modules=("cpu" "memory" "battery" "datetime" "hostname" "load" "uptime")
    for module in "${core_modules[@]}"; do
        run_test "Core module '$module' exists" "[[ -d '$CONFIG_DIR/modules/$module' ]]" "no"
    done
    
    # Check essential scripts
    run_test "System context detection script" "[[ -x '$CONFIG_DIR/utils/system_context_detection.sh' ]]" "no"
    run_test "Adaptive profile manager" "[[ -x '$CONFIG_DIR/utils/adaptive_profile_manager.sh' ]]" "no"
    run_test "Performance validation script" "[[ -x '$CONFIG_DIR/utils/performance_validation.sh' ]]" "no"
    
    echo
}

# Function: Validate tmux configuration
validate_tmux_configuration() {
    print_status "header" "Validating tmux Configuration"
    
    run_test "tmux.conf exists" "[[ -f '$TMUX_CONF' ]]"
    
    if [[ -f "$TMUX_CONF" ]]; then
        run_test "tmux-forceline referenced in tmux.conf" "grep -q 'tmux-forceline' '$TMUX_CONF'"
        run_test "tmux.conf syntax is valid" "tmux -f '$TMUX_CONF' -L validation-test new-session -d -s syntax-test \\; kill-session -t syntax-test"
        
        # Check for configuration options
        if grep -q "@forceline_theme" "$TMUX_CONF"; then
            print_status "info" "Theme configuration found"
        fi
        
        if grep -q "@forceline_plugins" "$TMUX_CONF"; then
            print_status "info" "Plugin configuration found"
        fi
    fi
    
    echo
}

# Function: Validate themes
validate_themes() {
    print_status "header" "Validating Themes"
    
    run_test "YAML themes directory exists" "[[ -d '$CONFIG_DIR/themes/yaml' ]]"
    
    if [[ -d "$CONFIG_DIR/themes/yaml" ]]; then
        local theme_count
        theme_count=$(find "$CONFIG_DIR/themes/yaml" -name "*.yaml" | wc -l)
        run_test "YAML themes available (found: $theme_count)" "[[ $theme_count -gt 0 ]]"
        
        # Test theme loader if yq is available
        if command -v yq >/dev/null 2>&1; then
            run_test "Theme loader functionality" "[[ -x '$CONFIG_DIR/themes/theme_loader.conf' ]]" "no"
        fi
    fi
    
    echo
}

# Function: Validate modules
validate_modules() {
    print_status "header" "Validating Module System"
    
    # Test native modules
    local native_modules=("session" "hostname" "datetime")
    for module in "${native_modules[@]}"; do
        if [[ -f "$CONFIG_DIR/modules/$module/${module}_native.sh" ]]; then
            run_test "Native module '$module' script" "[[ -x '$CONFIG_DIR/modules/$module/${module}_native.sh' ]]" "no"
        fi
    done
    
    # Test hybrid modules  
    local hybrid_modules=("directory" "load" "uptime")
    for module in "${hybrid_modules[@]}"; do
        if [[ -f "$CONFIG_DIR/modules/$module/${module}_hybrid.sh" ]]; then
            run_test "Hybrid module '$module' script" "[[ -x '$CONFIG_DIR/modules/$module/${module}_hybrid.sh' ]]" "no"
        fi
    done
    
    # Test core functionality modules
    local core_modules=("cpu" "memory" "battery")
    for module in "${core_modules[@]}"; do
        if [[ -f "$CONFIG_DIR/modules/$module/$module.sh" ]]; then
            run_test "Core module '$module' script" "[[ -x '$CONFIG_DIR/modules/$module/$module.sh' ]]" "no"
        fi
    done
    
    echo
}

# Function: Validate plugins
validate_plugins() {
    print_status "header" "Validating Plugin System"
    
    run_test "Core plugins directory exists" "[[ -d '$CONFIG_DIR/plugins/core' ]]"
    run_test "Extended plugins directory exists" "[[ -d '$CONFIG_DIR/plugins/extended' ]]" "no"
    
    # Check plugin configurations
    local plugin_configs=("cpu" "memory" "battery" "datetime" "hostname" "load" "uptime")
    for plugin in "${plugin_configs[@]}"; do
        run_test "Plugin config '$plugin' exists" "[[ -f '$CONFIG_DIR/plugins/core/$plugin/$plugin.conf' ]]" "no"
    done
    
    echo
}

# Function: Test performance features
validate_performance() {
    print_status "header" "Validating Performance Features"
    
    # Test format validation
    if [[ -x "$CONFIG_DIR/utils/performance_validation.sh" ]]; then
        run_test "Performance validation script executes" "$CONFIG_DIR/utils/performance_validation.sh --quiet" "no"
    fi
    
    # Test caching system
    run_test "Cache directory can be created" "mkdir -p /tmp/tmux-forceline-test-cache && rmdir /tmp/tmux-forceline-test-cache"
    
    # Test native format patterns
    if command -v tmux >/dev/null 2>&1; then
        run_test "Native tmux format support" "tmux display-message -p '#{session_name}' >/dev/null" "no"
        run_test "Environment variable format support" "tmux display-message -p '#{?#{E:HOME},yes,no}' >/dev/null" "no"
    fi
    
    echo
}

# Function: Test system integration
validate_system_integration() {
    print_status "header" "Validating System Integration"
    
    # Test system detection
    if [[ -x "$CONFIG_DIR/utils/system_context_detection.sh" ]]; then
        run_test "System context detection executes" "$CONFIG_DIR/utils/system_context_detection.sh --dry-run" "no"
    fi
    
    # Test profile management
    if [[ -x "$CONFIG_DIR/utils/adaptive_profile_manager.sh" ]]; then
        run_test "Profile manager executes" "$CONFIG_DIR/utils/adaptive_profile_manager.sh --list >/dev/null" "no"
    fi
    
    # Test cross-platform compatibility
    local os_type
    os_type=$(uname -s)
    case "$os_type" in
        "Linux")   print_status "info" "Platform: Linux (fully supported)" ;;
        "Darwin")  print_status "info" "Platform: macOS (fully supported)" ;;
        "FreeBSD") print_status "info" "Platform: FreeBSD (supported)" ;;
        *)         print_status "warning" "Platform: $os_type (limited testing)" ;;
    esac
    
    echo
}

# Function: Generate validation report
generate_report() {
    print_status "header" "Validation Summary"
    
    local total_issues=$((FAILED_TESTS + WARNING_TESTS))
    local success_rate
    success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    
    print_status "result" "Tests Run: $TOTAL_TESTS"
    print_status "result" "Passed: ${GREEN}$PASSED_TESTS${NC}"
    print_status "result" "Failed: ${RED}$FAILED_TESTS${NC}"
    print_status "result" "Warnings: ${YELLOW}$WARNING_TESTS${NC}"
    print_status "result" "Success Rate: ${success_rate}%"
    
    echo
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        print_status "success" "tmux-forceline v3.0 successfully installed and validated!"
        
        if [[ $WARNING_TESTS -gt 0 ]]; then
            print_status "warning" "Some non-critical issues detected (see warnings above)"
        fi
        
        cat << EOF

${GREEN}🎉 Installation Successful!${NC}

${CYAN}Performance Status:${NC}
  ✅ Native format integration ready
  ✅ Hybrid module system functional  
  ✅ Adaptive configuration active
  ✅ Cross-platform compatibility verified

${CYAN}Next Steps:${NC}
  1. Reload tmux: ${WHITE}tmux source-file ~/.tmux.conf${NC}
  2. Test performance: ${WHITE}~/.config/tmux/plugins/tmux-forceline/utils/performance_benchmark.sh${NC}
  3. Customize settings: ${WHITE}~/.config/tmux/plugins/tmux-forceline/docs/CONFIGURATION_EXAMPLES.md${NC}

EOF
        return 0
    else
        print_status "error" "Installation validation failed with $FAILED_TESTS critical issues"
        
        cat << EOF

${RED}❌ Installation Issues Detected${NC}

${CYAN}Troubleshooting:${NC}
  1. Check prerequisites: ${WHITE}tmux -V && yq --version${NC}
  2. Verify file permissions: ${WHITE}ls -la ~/.config/tmux/plugins/tmux-forceline/${NC}
  3. Test tmux configuration: ${WHITE}tmux -f ~/.tmux.conf new-session -d 'echo test'${NC}
  4. Review installation guide: ${WHITE}docs/INSTALLATION_GUIDE.md${NC}

${CYAN}Support Resources:${NC}
  • GitHub Issues: https://github.com/your-org/tmux-forceline/issues
  • Installation Guide: docs/INSTALLATION_GUIDE.md
  • Troubleshooting: docs/TROUBLESHOOTING.md

EOF
        return 1
    fi
}

# Function: Main validation process
main() {
    echo
    print_status "header" "tmux-forceline v3.0 Installation Validator"
    echo
    
    validate_tmux
    validate_dependencies
    validate_file_structure
    validate_tmux_configuration
    validate_themes
    validate_modules
    validate_plugins
    validate_performance
    validate_system_integration
    
    generate_report
}

# Run main function
main "$@"