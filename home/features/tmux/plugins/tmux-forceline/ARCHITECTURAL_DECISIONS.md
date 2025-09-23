# Architectural Decision Record (ADR)
## tmux-forceline v3.0 Tao of Tmux Alignment

---

## ADR-001: Intelligent Caching Framework Architecture

**Date**: 2024-01-20  
**Status**: Proposed  
**Decision Makers**: tmux-forceline Core Team  

### Context
Current caching system uses uniform TTL across all modules, leading to:
- Over-caching of fast-changing data (CPU, network)
- Under-caching of slow-changing data (weather, WAN IP)
- No adaptation to system load or usage patterns
- Performance inconsistencies across different system configurations

### Decision
Implement a profile-based intelligent caching framework with:
1. **Module-Specific Cache Profiles**: Each module gets appropriate TTL based on data volatility
2. **Adaptive TTL**: Dynamic adjustment based on system load and user behavior
3. **Cache Warming**: Proactive updates for expensive operations
4. **Performance Monitoring**: Built-in metrics for optimization

### Rationale
- **Tao Alignment**: Efficiency principle - optimize system resource usage
- **Performance**: Reduce unnecessary shell command execution by 60-80%
- **User Experience**: Consistent responsiveness regardless of system load
- **Maintainability**: Clear separation of concerns between caching and data generation

### Implementation Details
```bash
# Cache profile definitions
declare -A CACHE_PROFILES=(
    ["cpu"]="2"          # High volatility, frequent updates needed
    ["memory"]="3"       # Medium volatility
    ["battery"]="30"     # Low volatility on battery-powered devices
    ["weather"]="900"    # Very low volatility, external API limits
    ["wan_ip"]="3600"    # Extremely low volatility
)

# Adaptive behavior
adjust_cache_ttl() {
    local module="$1"
    local base_ttl="${CACHE_PROFILES[$module]}"
    local system_load="$(get_system_load)"
    
    if (( $(echo "$system_load > 0.8" | bc -l) )); then
        # High load: Extend TTL to reduce system pressure
        echo $((base_ttl * 2))
    else
        echo "$base_ttl"
    fi
}
```

### Consequences
**Positive**:
- Significant performance improvement (estimated 60-80% reduction in shell calls)
- Better system resource utilization
- Improved user experience under load
- Foundation for advanced features

**Negative**:
- Increased complexity in cache management
- Need for migration strategy from current simple caching
- Additional testing requirements for cache behavior

**Risks**:
- Cache invalidation complexity
- Potential for stale data if TTL logic is incorrect
- Memory usage increase for cache metadata

---

## ADR-002: Background Daemon Architecture

**Date**: 2024-01-20  
**Status**: Proposed  
**Decision Makers**: tmux-forceline Core Team  

### Context
Current synchronous execution model causes:
- Status bar blocking during expensive operations
- CPU spikes when multiple modules update simultaneously
- Poor user experience with network-dependent modules
- No ability to pre-compute expensive operations

### Decision
Implement a lightweight background daemon with:
1. **Asynchronous Processing**: Expensive operations run independently
2. **Priority Queue**: Intelligently schedule updates based on importance
3. **IPC via tmux Environment**: Use native tmux capabilities for communication
4. **Graceful Degradation**: Fall back to synchronous mode if daemon unavailable

### Rationale
- **Tao Alignment**: Native tmux integration using environment variables
- **Performance**: Non-blocking status bar updates
- **Reliability**: Fault tolerance with fallback mechanisms
- **Simplicity**: Leverage tmux's built-in IPC rather than external dependencies

### Implementation Details
```bash
# Daemon lifecycle management
tmux-forceline-daemon() {
    case "$1" in
        start)
            if ! tmux show-environment -g FORCELINE_DAEMON_PID 2>/dev/null; then
                nohup bash "$0" --daemon-mode & 
                tmux set-environment -g FORCELINE_DAEMON_PID $!
            fi
            ;;
        stop)
            local pid=$(tmux show-environment -g FORCELINE_DAEMON_PID 2>/dev/null | cut -d= -f2)
            [[ -n "$pid" ]] && kill "$pid" 2>/dev/null
            tmux set-environment -gu FORCELINE_DAEMON_PID
            ;;
        status)
            local pid=$(tmux show-environment -g FORCELINE_DAEMON_PID 2>/dev/null | cut -d= -f2)
            [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null && echo "running" || echo "stopped"
            ;;
    esac
}

# IPC communication using tmux environment
daemon_set_value() {
    local module="$1"
    local value="$2"
    local timestamp="$(date +%s)"
    tmux set-environment -g "FORCELINE_${module}_VALUE" "$value"
    tmux set-environment -g "FORCELINE_${module}_TIMESTAMP" "$timestamp"
}

daemon_get_value() {
    local module="$1"
    tmux show-environment -g "FORCELINE_${module}_VALUE" 2>/dev/null | cut -d= -f2
}
```

### Consequences
**Positive**:
- Responsive status bar regardless of expensive operations
- Better system resource utilization through scheduling
- Foundation for advanced features like predictive updating
- Native tmux integration maintains simplicity

**Negative**:
- Additional complexity in daemon lifecycle management
- Need for robust error handling and recovery
- Slightly increased memory usage for daemon process

**Risks**:
- Daemon crash scenarios need handling
- IPC failure modes must be considered
- Potential for data inconsistency if synchronization fails

---

## ADR-003: Hybrid Format Integration Strategy

**Date**: 2024-01-20  
**Status**: Proposed  
**Decision Makers**: tmux-forceline Core Team  

### Context
Current implementation uses 100% shell command execution via `#()` syntax:
- Misses opportunities for zero-cost native tmux formats
- Unnecessary shell overhead for static or tmux-native information
- No utilization of tmux's built-in variable system

### Decision
Implement a hybrid approach combining:
1. **Native tmux formats** for tmux-internal data (sessions, windows, panes)
2. **Shell commands** only when necessary for system data
3. **Hybrid modules** that combine both approaches optimally
4. **Fallback mechanisms** for compatibility

### Rationale
- **Tao Alignment**: Leverage tmux's native capabilities before external commands
- **Performance**: Native formats have zero computational cost
- **Reliability**: Reduce dependency on shell command execution
- **Simplicity**: Use the right tool for each type of data

### Implementation Details
```bash
# Pure native format (zero cost)
session_info="#{session_name}:#{window_index}.#{pane_index}"

# Hybrid approach (minimal shell overhead)
hostname="#{host_short}#(/path/to/hostname_color.sh #{host_short})"

# Full shell when necessary
cpu_percentage="#(/path/to/cpu_percentage.sh)"

# Conversion priority matrix
CONVERSION_CANDIDATES=(
    # High priority: Pure native possible
    "session_info:NATIVE"
    "window_info:NATIVE" 
    "pane_info:NATIVE"
    
    # Medium priority: Hybrid beneficial
    "hostname:HYBRID"
    "datetime:HYBRID"
    
    # Low priority: Shell required
    "cpu_percentage:SHELL"
    "memory_usage:SHELL"
    "network_stats:SHELL"
)
```

### Module Conversion Strategy
1. **Phase 1**: Convert pure native candidates (session, window, pane info)
2. **Phase 2**: Implement hybrid modules for partially convertible modules
3. **Phase 3**: Optimize shell-required modules for performance

### Consequences
**Positive**:
- Significant performance improvement for converted modules
- Better integration with tmux's native capabilities
- Reduced system resource usage
- Foundation for advanced tmux integrations

**Negative**:
- Increased implementation complexity
- Need for dual-mode testing
- Documentation overhead for hybrid approaches

**Risks**:
- tmux version compatibility for format strings
- Fallback complexity if native formats fail
- Potential for inconsistent behavior between modes

---

## ADR-004: Performance Budgeting System

**Date**: 2024-01-20  
**Status**: Proposed  
**Decision Makers**: tmux-forceline Core Team  

### Context
Users have different performance requirements and system capabilities:
- Laptop users need battery-conscious configurations
- Server administrators want comprehensive monitoring
- Development machines need fast updates for coding workflows
- No current way to balance features vs performance trade-offs

### Decision
Implement a performance budgeting system with:
1. **Predefined Budget Levels**: Conservative, Balanced, Aggressive
2. **Resource Monitoring**: Track CPU, memory, and update frequency
3. **Automatic Enforcement**: Adjust configuration to stay within budget
4. **User Override**: Allow manual configuration while providing guidance

### Rationale
- **Tao Alignment**: Simplicity through intelligent defaults
- **User Experience**: Optimal configuration without manual tuning
- **Performance**: Predictable resource usage
- **Flexibility**: Power users can still customize everything

### Implementation Details
```bash
# Performance budget definitions
declare -A BUDGET_CONSERVATIVE=(
    ["update_interval"]="10"
    ["max_modules"]="4"
    ["cache_aggressiveness"]="high"
    ["background_updates"]="false"
)

declare -A BUDGET_BALANCED=(
    ["update_interval"]="5"
    ["max_modules"]="8"
    ["cache_aggressiveness"]="medium"
    ["background_updates"]="true"
)

declare -A BUDGET_AGGRESSIVE=(
    ["update_interval"]="2"
    ["max_modules"]="unlimited"
    ["cache_aggressiveness"]="low"
    ["background_updates"]="true"
)

# Budget enforcement
enforce_budget() {
    local budget_level="$1"
    local current_usage="$(measure_resource_usage)"
    
    if budget_exceeded "$budget_level" "$current_usage"; then
        adjust_configuration_for_budget "$budget_level"
        notify_user_of_adjustment
    fi
}
```

### Consequences
**Positive**:
- Better out-of-box experience for all user types
- Predictable performance characteristics
- Foundation for automatic optimization
- Clear guidance for performance tuning

**Negative**:
- Additional complexity in configuration management
- Need for accurate resource measurement
- Potential user confusion about automatic adjustments

**Risks**:
- Budget enforcement may be too aggressive
- Resource measurement accuracy across platforms
- User expectation management for automatic changes

---

## ADR-005: Backward Compatibility Strategy

**Date**: 2024-01-20  
**Status**: Proposed  
**Decision Makers**: tmux-forceline Core Team  

### Context
Major architectural changes risk breaking existing user configurations:
- Users have invested time in customizing tmux-forceline
- Enterprise environments need stable, predictable behavior
- Plugin ecosystem depends on current interfaces
- Migration complexity should not burden users

### Decision
Implement comprehensive backward compatibility with:
1. **Configuration Translation**: Automatic conversion of old to new format
2. **Fallback Mechanisms**: Graceful degradation when new features unavailable
3. **Feature Flags**: Gradual rollout of new capabilities
4. **Migration Tools**: Automated assistance for complex changes

### Rationale
- **User Experience**: Seamless upgrades without configuration breakage
- **Adoption**: Lower barriers to upgrading encourage adoption
- **Enterprise Ready**: Predictable behavior for production environments
- **Community**: Maintain trust and goodwill with existing users

### Implementation Details
```bash
# Configuration version detection and migration
migrate_configuration() {
    local config_version="$(get_config_version)"
    
    case "$config_version" in
        "2.0"|"2.1")
            migrate_v2_to_v3 "$config_file"
            ;;
        "3.0")
            # Already current
            ;;
        *)
            # Default migration path
            apply_intelligent_defaults
            ;;
    esac
}

# Feature flag system
is_feature_enabled() {
    local feature="$1"
    local default="$2"
    get_tmux_option "@forceline_feature_${feature}" "$default"
}

# Graceful degradation
with_fallback() {
    local primary_method="$1"
    local fallback_method="$2"
    
    if ! $primary_method 2>/dev/null; then
        $fallback_method
    fi
}
```

### Migration Timeline
1. **v3.0.0**: New features behind feature flags, full backward compatibility
2. **v3.1.0**: New features enabled by default, old methods deprecated
3. **v3.2.0**: Old methods removed, new architecture fully active

### Consequences
**Positive**:
- Smooth user experience during major version upgrade
- Reduced support burden from broken configurations
- Higher adoption rate of new features
- Enterprise-friendly upgrade path

**Negative**:
- Increased code complexity during transition period
- Additional testing requirements for compatibility modes
- Delayed benefits from architectural improvements

**Risks**:
- Complex migration logic may introduce bugs
- Feature flag management complexity
- Performance overhead from compatibility layers

---

## ADR-006: Testing and Quality Assurance Strategy

**Date**: 2024-01-20  
**Status**: Proposed  
**Decision Makers**: tmux-forceline Core Team  

### Context
Major architectural changes require comprehensive testing:
- Performance claims must be validated with benchmarks
- Cross-platform compatibility is critical
- User experience improvements need measurement
- Regression prevention is essential

### Decision
Implement comprehensive testing framework with:
1. **Performance Benchmarking**: Automated performance regression detection
2. **Cross-Platform Testing**: Linux, macOS, BSD, WSL validation
3. **User Experience Testing**: Real-world scenario validation
4. **Integration Testing**: Plugin ecosystem compatibility

### Implementation Details
```bash
# Performance benchmark suite
run_performance_tests() {
    local baseline_results="benchmarks/baseline_v2.json"
    local current_results="benchmarks/current_$(date +%Y%m%d).json"
    
    benchmark_cache_performance
    benchmark_module_execution_time
    benchmark_memory_usage
    benchmark_cpu_utilization
    
    compare_performance "$baseline_results" "$current_results"
}

# Cross-platform test matrix
PLATFORMS=("ubuntu-latest" "macos-latest" "freebsd-latest")
TMUX_VERSIONS=("3.0" "3.1" "3.2" "3.3")

# User experience metrics
measure_ux_metrics() {
    measure_time_to_first_success
    measure_configuration_error_rate
    measure_feature_discovery_rate
    measure_performance_satisfaction
}
```

### Quality Gates
- **Performance**: No regression >5% in any benchmark
- **Compatibility**: 100% test pass rate on all supported platforms
- **Coverage**: >90% code coverage for core functionality
- **Documentation**: 100% API documentation coverage

### Consequences
**Positive**:
- High confidence in performance improvements
- Early detection of regressions
- Platform compatibility assurance
- Data-driven optimization decisions

**Negative**:
- Significant initial investment in test infrastructure
- Ongoing maintenance of test suite
- Potential development velocity impact

**Risks**:
- Test suite maintenance complexity
- False positive/negative test results
- Platform-specific test failures

---

## Decision Summary

| ADR | Decision | Impact | Risk Level |
|-----|----------|---------|------------|
| ADR-001 | Intelligent Caching | High Performance Gain | Medium |
| ADR-002 | Background Daemon | High UX Improvement | Medium |
| ADR-003 | Hybrid Format Integration | Medium Performance Gain | Low |
| ADR-004 | Performance Budgeting | High UX Improvement | Low |
| ADR-005 | Backward Compatibility | High Adoption | Medium |
| ADR-006 | Testing Strategy | Risk Mitigation | Low |

---

## Implementation Priorities

### Critical Path (Must Implement First):
1. **ADR-001**: Intelligent Caching - Foundation for all performance improvements
2. **ADR-005**: Backward Compatibility - Required for user trust
3. **ADR-006**: Testing Strategy - Risk mitigation for major changes

### High Value (Implement Early):
4. **ADR-002**: Background Daemon - Major UX improvement
5. **ADR-004**: Performance Budgeting - Better defaults for users

### Optimization (Implement Later):
6. **ADR-003**: Hybrid Format Integration - Performance optimization

---

## Success Criteria

### Technical Success:
- [ ] 60%+ reduction in shell command execution
- [ ] <100ms status bar update latency
- [ ] <1% average CPU usage
- [ ] >95% backward compatibility

### User Success:
- [ ] <5 minute time-to-first-success
- [ ] <5% configuration error rate
- [ ] >90% user satisfaction with performance
- [ ] >70% adoption of new features

### Project Success:
- [ ] Zero critical bugs in production
- [ ] Complete documentation coverage
- [ ] Active community engagement
- [ ] Positive technical recognition

---

*Document Version: 1.0*  
*Last Updated: 2024-01-20*  
*Next Review: 2024-02-03*