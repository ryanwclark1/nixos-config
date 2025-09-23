# tmux-forceline v3.0 Configuration Examples

Practical examples showcasing the revolutionary performance improvements and intelligent features of tmux-forceline v3.0.

---

## 🚀 Quick Start Examples

### Zero-Configuration Setup
```bash
# Add to ~/.tmux.conf - Everything else is automatic
run-shell ~/.tmux/plugins/tmux-forceline/forceline.tmux

# tmux-forceline v3.0 will:
# 1. Detect your system (laptop/desktop/server/development)
# 2. Apply optimal profile automatically
# 3. Configure modules based on your hardware
# 4. Optimize for your power source and network
```

### Verify Automatic Configuration
```bash
# Check what profile was automatically applied
~/.tmux/plugins/tmux-forceline/utils/adaptive_profile_manager.sh status

# Example output:
# Current Profile Status:
# ======================
# Active Profile: development
# Applied: 2025-09-19T13:58:17-05:00
# 
# Profile Description: Enhanced for development workflows
# 
# Configuration:
#   update_interval     : 3
#   cache_ttl          : 20
#   modules            : session,hostname,datetime,directory,vcs,cpu,memory
#   network_modules    : true
#   background_updates : true
#   visual_complexity  : medium
#   color_scheme       : development
#   icons              : selective
#   animations         : subtle
```

---

## 🎯 Profile-Specific Configurations

### Laptop Profile (Battery Optimized)
```bash
# Apply laptop profile manually
~/.tmux/plugins/tmux-forceline/utils/adaptive_profile_manager.sh apply laptop

# What this configures:
# - Update interval: 5 seconds (conserves CPU)
# - Cache TTL: 30 seconds (reduces disk I/O)
# - Modules: session,hostname,datetime,battery,directory (essential only)
# - Network modules: disabled (saves battery)
# - Visual complexity: low (reduces GPU usage)
# - Color scheme: battery_aware (changes with power status)

# Resulting tmux.conf equivalent:
set -g @forceline_profile 'laptop'
set -g @forceline_update_interval '5'
set -g @forceline_cache_ttl '30'
set -g @forceline_modules 'session,hostname,datetime,battery,directory'
set -g @forceline_network_modules 'false'
set -g @forceline_visual_complexity 'low'
set -g @forceline_color_scheme 'battery_aware'
```

### Desktop Profile (High Performance)
```bash
# Apply desktop profile for workstations
~/.tmux/plugins/tmux-forceline/utils/adaptive_profile_manager.sh apply desktop

# What this configures:
# - Update interval: 2 seconds (responsive updates)
# - Cache TTL: 15 seconds (fresh information)
# - Modules: session,hostname,datetime,directory,cpu,memory,load,vcs (full set)
# - Network modules: enabled (includes wan_ip, lan_ip)
# - Visual complexity: high (rich styling)
# - Color scheme: full (complete color palette)

# Resulting configuration:
set -g @forceline_profile 'desktop'
set -g @forceline_update_interval '2'
set -g @forceline_cache_ttl '15'
set -g @forceline_modules 'session,hostname,datetime,directory,cpu,memory,load,vcs'
set -g @forceline_network_modules 'true'
set -g @forceline_visual_complexity 'high'
set -g @forceline_color_scheme 'full'
set -g @forceline_icons 'full'
set -g @forceline_animations 'true'
```

### Server Profile (Minimal Resources)
```bash
# Apply server profile for headless systems
~/.tmux/plugins/tmux-forceline/utils/adaptive_profile_manager.sh apply server

# What this configures:
# - Update interval: 10 seconds (minimal CPU usage)
# - Cache TTL: 60 seconds (maximum efficiency)
# - Modules: session,hostname,datetime,uptime,load,memory (system health focus)
# - Network modules: disabled (no external dependencies)
# - Visual complexity: minimal (text-only)
# - Color scheme: monochrome (minimal styling)

# Resulting configuration:
set -g @forceline_profile 'server'
set -g @forceline_update_interval '10'
set -g @forceline_cache_ttl '60'
set -g @forceline_modules 'session,hostname,datetime,uptime,load,memory'
set -g @forceline_network_modules 'false'
set -g @forceline_visual_complexity 'minimal'
set -g @forceline_color_scheme 'monochrome'
set -g @forceline_icons 'none'
set -g @forceline_animations 'false'
```

### Development Profile (VCS Enhanced)
```bash
# Apply development profile for coding environments
~/.tmux/plugins/tmux-forceline/utils/adaptive_profile_manager.sh apply development

# What this configures:
# - Enhanced VCS integration (git branch, status, modifications)
# - Directory awareness (project navigation)
# - Development tool detection (npm, cargo, docker status)
# - Balanced performance (responsive but not wasteful)

# Resulting configuration:
set -g @forceline_profile 'development'
set -g @forceline_update_interval '3'
set -g @forceline_modules 'session,hostname,datetime,directory,vcs,cpu,memory'
set -g @forceline_vcs_integration 'enhanced'
set -g @forceline_directory_project_detection 'true'
set -g @forceline_development_tools 'true'
```

---

## 🎨 Visual Configuration Examples

### Status Line with Native Formats (100% Performance)
```bash
# Traditional v2.x approach (slow, shell-based)
set -g status-left "#[fg=green]$(hostname -s)#[default] | "
set -g status-right "$(date +%H:%M:%S) | $(basename $(pwd))"

# v3.0 native approach (100% improvement, zero shell overhead)
set -g status-left "#[fg=green]#{host_short}#[default] | "
set -g status-right "#{T:%H:%M:%S} | #{b:pane_current_path}"

# Advanced native conditional formatting (500%+ improvement)
set -g status-left "#{?client_prefix,#[fg=yellow]⌘ ,#[fg=green]● }#{session_name} #[default]"
set -g status-right "#{?#{>:#{length:pane_current_path},30},#{s|.*/(.*/.*/.*)|...$1|:pane_current_path},#{s|$HOME|~|:pane_current_path}} | #{T:%H:%M}"
```

### Hybrid Format Status Line (60% Performance + Rich Features)
```bash
# Hybrid approach: native display + cached calculations
set -g status-left "#{E:FORCELINE_HOSTNAME_ICON}#{host_short} "
set -g status-right "#{E:FORCELINE_LOAD_STATUS} | #{E:FORCELINE_UPTIME_FORMATTED} | #{T:%H:%M}"

# With conditional styling based on cached data
set -g status-right "#{?#{E:FORCELINE_LOAD_HIGH},#[fg=red],#{?#{E:FORCELINE_LOAD_MEDIUM},#[fg=yellow],#[fg=green]}}#{E:FORCELINE_LOAD_CURRENT}#[default] | #{T:%H:%M}"
```

### Complex Conditional Examples
```bash
# Session state with multiple conditions (native, zero overhead)
set -g status-left "#{?session_many_attached,#[fg=red]◆,#{?client_prefix,#[fg=yellow]⌘,#[fg=green]●}} #{session_name} #[default]"

# Path display with intelligent truncation
set -g status-right "#{?#{>:#{length:pane_current_path},50},#{s|.*/(.*/.*/.*)$|...$1|:pane_current_path},#{s|$HOME|~|:pane_current_path}}"

# Battery-aware coloring (when battery module is active)
set -g status-right "#{?#{E:FORCELINE_BATTERY_LOW},#[fg=red],#{?#{E:FORCELINE_BATTERY_CHARGING},#[fg=yellow],#[fg=green]}}#{E:FORCELINE_BATTERY_PERCENTAGE}#[default]"
```

---

## ⚙️ Performance-Optimized Configurations

### Maximum Performance Configuration
```bash
# For systems where every millisecond counts
set -g @forceline_profile 'performance'
set -g @forceline_update_interval '1'        # Maximum responsiveness
set -g @forceline_cache_ttl '5'              # Fresh data
set -g @forceline_modules 'session,hostname,datetime,directory,cpu,memory,load,vcs,network,battery'
set -g @forceline_background_updates 'true'  # Use background daemon
set -g @forceline_visual_complexity 'maximum'
set -g @forceline_animations 'true'

# Status line leveraging all native capabilities
set -g status-left "#{?client_prefix,#[fg=yellow]⌘ PREFIX,#[fg=green]● NORMAL} #{session_name}:#{window_index}.#{pane_index} #[default]"
set -g status-right "#{E:FORCELINE_VCS_BRANCH} #{E:FORCELINE_CPU_STATUS} #{E:FORCELINE_MEMORY_STATUS} #{T:%H:%M:%S}"
```

### Minimal Resource Configuration
```bash
# For resource-constrained environments
set -g @forceline_profile 'minimal'
set -g @forceline_update_interval '30'       # Minimal CPU usage
set -g @forceline_cache_ttl '300'            # Maximum cache efficiency
set -g @forceline_modules 'session,hostname' # Essential only
set -g @forceline_background_updates 'false' # No background processes
set -g @forceline_visual_complexity 'none'   # Text only
set -g @forceline_icons 'none'
set -g @forceline_animations 'false'

# Ultra-minimal status line (native only)
set -g status-left "#{session_name} "
set -g status-right "#{host_short} #{T:%H:%M}"
```

### Balanced Performance Configuration
```bash
# Optimal balance for most users
set -g @forceline_profile 'balanced'
set -g @forceline_update_interval '5'        # Good responsiveness
set -g @forceline_cache_ttl '30'             # Reasonable efficiency
set -g @forceline_modules 'session,hostname,datetime,directory,cpu'
set -g @forceline_network_modules 'false'    # Avoid network dependencies
set -g @forceline_visual_complexity 'medium'
set -g @forceline_icons 'selective'

# Status line balancing features and performance
set -g status-left "#{?client_prefix,#[fg=yellow]⌘,#[fg=green]●} #{session_name} #[default]"
set -g status-right "#{b:pane_current_path} | #{E:FORCELINE_CPU_PERCENTAGE} | #{T:%H:%M}"
```

---

## 🎯 Use Case-Specific Examples

### Remote SSH Sessions
```bash
# Optimized for network-dependent environments
set -g @forceline_profile 'cloud'
set -g @forceline_network_modules 'false'    # No external requests
set -g @forceline_update_interval '15'       # Conservative updates
set -g @forceline_modules 'session,hostname,datetime,uptime'

# Status line showing connection context
set -g status-left "#[fg=cyan]SSH#[default] #{host_short}:#{session_name} "
set -g status-right "#{E:FORCELINE_UPTIME_COMPACT} | #{T:%H:%M %Z}"
```

### Development Workflows
```bash
# Enhanced for software development
set -g @forceline_profile 'development'
set -g @forceline_vcs_integration 'enhanced'
set -g @forceline_directory_project_detection 'true'
set -g @forceline_modules 'session,hostname,datetime,directory,vcs,cpu,memory'

# Status line with VCS integration
set -g status-left "#{session_name}:#{window_index} #{?client_prefix,#[fg=yellow]⌘,} #[default]"
set -g status-right "#{E:FORCELINE_VCS_BRANCH} #{E:FORCELINE_VCS_STATUS} | #{s|$HOME|~|:pane_current_path} | #{T:%H:%M}"
```

### System Monitoring
```bash
# Focus on system health and performance
set -g @forceline_profile 'server'
set -g @forceline_modules 'session,hostname,datetime,uptime,load,memory,cpu'
set -g @forceline_load_thresholds 'custom'   # Custom load warning levels
set -g @forceline_memory_warning_threshold '80'

# Status line emphasizing system metrics
set -g status-left "#{host_short} UP:#{E:FORCELINE_UPTIME_COMPACT} "
set -g status-right "#{?#{E:FORCELINE_LOAD_HIGH},#[fg=red],#[fg=green]}LD:#{E:FORCELINE_LOAD_CURRENT}#[default] #{?#{E:FORCELINE_MEMORY_HIGH},#[fg=red],#[fg=green]}MEM:#{E:FORCELINE_MEMORY_PERCENTAGE}#[default] #{T:%H:%M}"
```

---

## 🔧 Migration Examples

### From tmux-powerline
```bash
# Before (tmux-powerline approach)
set -g status-left "#[fg=white,bg=blue,bold] #S #[fg=blue,bg=black,nobold,noitalics,nounderscore]"
set -g status-right "#[fg=brightblack,bg=black,nobold,noitalics,nounderscore]#[fg=white,bg=brightblack] %Y-%m-%d #[fg=white,bg=brightblack,nobold,noitalics,nounderscore]#[fg=white,bg=brightblack] %H:%M:%S #[fg=blue,bg=brightblack,nobold,noitalics,nounderscore]#[fg=white,bg=blue,bold] #H "

# After (tmux-forceline v3.0 - native, 100% performance improvement)
set -g status-left "#[fg=white,bg=blue,bold] #{session_name} #[fg=blue,bg=black,nobold]"
set -g status-right "#[fg=brightblack,bg=black]#[fg=white,bg=brightblack] #{T:%Y-%m-%d} #[fg=white,bg=brightblack] #{T:%H:%M:%S} #[fg=blue,bg=brightblack]#[fg=white,bg=blue,bold] #{host_short} "

# Auto-migrate using conversion tool
~/.tmux/plugins/tmux-forceline/utils/format_converter.sh convert ~/.tmux.conf
```

### From Custom Shell Scripts
```bash
# Before (custom shell script approach)
set -g status-right "#(custom_script.sh cpu) | #(custom_script.sh memory) | #(date +'%H:%M')"

# After (hybrid approach - 60% improvement + enhanced features)
set -g status-right "#{E:FORCELINE_CPU_STATUS} | #{E:FORCELINE_MEMORY_STATUS} | #{T:%H:%M}"

# The hybrid modules provide:
# - Cached calculations (no repeated shell execution)
# - Enhanced features (trend detection, thresholds, colors)
# - Native display (zero tmux overhead)
# - Cross-platform compatibility
```

### From Basic tmux Status
```bash
# Before (basic tmux built-ins)
set -g status-left "[#S] "
set -g status-right " \"#H\" %H:%M %d-%b-%y"

# After (enhanced native with zero performance cost)
set -g status-left "#{?client_prefix,#[fg=yellow]⌘,#[fg=green]●} [#{session_name}] #[default]"
set -g status-right " \"#{host_short}\" #{T:%H:%M %d-%b-%y}"

# Additional enhancements available:
set -g status-right "#{?session_many_attached,#[fg=red]MULTI,#[fg=green]SINGLE} \"#{host_short}\" #{T:%H:%M %d-%b-%y}"
```

---

## 🧪 Testing and Validation Examples

### Performance Comparison
```bash
# Test your current configuration performance
~/.tmux/plugins/tmux-forceline/utils/performance_validation.sh

# Example output:
# 🚀 tmux-forceline v3.0 Performance Validation
# ==============================================
# 
# ✅ tmux environment: Ready
# 
# 📊 1. Native Format Validation
# ==============================
# Testing native session format... ✅ Works: '1'
# Testing native hostname format... ✅ Works: 'hostname'
# Testing native datetime format... ✅ Works: '13:58:17'
# Testing native path format... ✅ Works: 'current-dir'
# 
# 🎯 2. Advanced Conditional Format Validation
# ============================================
# Testing prefix conditional... ✅ Works: 'PREFIX_OFF'
# Testing session conditional... ✅ Works: 'SINGLE'
# Testing path length conditional... ✅ Works: 'SHORT_PATH'
# 
# 🏆 Performance Validation Summary
# ================================
# 
# ✅ Native Format Integration:
#    • Session, hostname, datetime modules converted
#    • Zero shell process creation
#    • 100% performance improvement achieved
```

### Format Conversion Testing
```bash
# Test individual format conversions
~/.tmux/plugins/tmux-forceline/utils/format_converter.sh test '$(hostname -s)'

# Example output:
# Original: $(hostname -s)
# Analysis:
# CONVERSIONS_FOUND: 1
# AVG_IMPROVEMENT: 100%
# DETAILS:
# NATIVE: $(hostname -s) → #{host_short} (100% improvement)
# 
# Conversion:
# Result: #{host_short}

# Test complex format strings
~/.tmux/plugins/tmux-forceline/utils/format_converter.sh test 'Server: $(hostname -s) | Time: $(date +%H:%M:%S) | Dir: $(basename $(pwd))'

# Shows all possible conversions and performance improvements
```

### System Analysis
```bash
# Analyze your system for optimal configuration
~/.tmux/plugins/tmux-forceline/utils/system_context_detection.sh

# Example output:
# # System Context Detection Report
# 
# Generated: Fri Sep 19 01:56:47 PM CDT 2025
# System: Linux 6.16.5-zen1
# 
# ## Hardware Information
# - CPU: 24 cores (x86_64)
# - Model: AMD Ryzen 9 7900X 12-Core Processor
# - Memory: 128020MB total, 99316MB available
# - Power: ac_adapter (battery: false)
# 
# ## Configuration Recommendations
# 
# ### Recommended Profile: development
# 
# - Update Interval: 3 seconds
# - Cache TTL: 20 seconds
# - Recommended Modules: session,hostname,datetime,directory,vcs,cpu,memory
# - Network Modules: true
# - Background Updates: true
```

---

## 🎨 Advanced Styling Examples

### Dynamic Color Schemes
```bash
# Battery-aware coloring
set -g status-right "#{?#{E:FORCELINE_BATTERY_LOW},#[fg=red]LOW,#{?#{E:FORCELINE_BATTERY_CHARGING},#[fg=yellow]CHG,#[fg=green]OK}} #{E:FORCELINE_BATTERY_PERCENTAGE}% | #{T:%H:%M}"

# Load-aware system colors
set -g status-left "#{?#{E:FORCELINE_LOAD_HIGH},#[bg=red]#[fg=white],#{?#{E:FORCELINE_LOAD_MEDIUM},#[bg=yellow]#[fg=black],#[bg=green]#[fg=white]}} #{session_name} #[default] "

# VCS status coloring
set -g status-right "#{?#{m:*modified*,#{E:FORCELINE_VCS_STATUS}},#[fg=yellow],#{?#{m:*ahead*,#{E:FORCELINE_VCS_STATUS}},#[fg=blue],#[fg=green]}}#{E:FORCELINE_VCS_BRANCH}#[default]"
```

### Progressive Enhancement
```bash
# Basic functionality (works everywhere)
set -g status-left "#{session_name} "
set -g status-right "#{host_short} #{T:%H:%M}"

# Enhanced with conditionals (tmux 2.6+)
set -g status-left "#{?client_prefix,#[fg=yellow]⌘ ,}#{session_name} #[default]"
set -g status-right "#{?session_many_attached,#[fg=red]MULTI,}#{host_short} #{T:%H:%M}"

# Full v3.0 features (tmux 3.0+ recommended)
set -g status-left "#{?client_prefix,#[fg=yellow]⌘ PREFIX,#{?session_many_attached,#[fg=red]◆ MULTI,#[fg=green]● SINGLE}} #{session_name}:#{window_index} #[default]"
set -g status-right "#{E:FORCELINE_LOAD_STATUS} #{s|$HOME|~|:pane_current_path} #{T:%H:%M:%S}"
```

---

## 📊 Real-World Configuration Examples

### Personal Laptop Setup
```bash
# ~/.tmux.conf for laptop user
run-shell ~/.tmux/plugins/tmux-forceline/forceline.tmux

# Force laptop profile for battery optimization
set -g @forceline_profile 'laptop'

# Custom status line emphasizing battery and essential info
set -g status-left "#{?client_prefix,#[fg=yellow]⌘,#[fg=green]●} #{session_name} #[default]"
set -g status-right "#{?#{E:FORCELINE_BATTERY_LOW},#[fg=red],#{?#{E:FORCELINE_BATTERY_CHARGING},#[fg=yellow],#[fg=green]}}#{E:FORCELINE_BATTERY_ICON}#{E:FORCELINE_BATTERY_PERCENTAGE}#[default] | #{s|$HOME|~|:pane_current_path} | #{T:%H:%M}"

# Power-aware module loading
set -g @forceline_battery_module 'enhanced'
set -g @forceline_network_modules 'false'  # Save battery
```

### Development Workstation
```bash
# ~/.tmux.conf for developer
run-shell ~/.tmux/plugins/tmux-forceline/forceline.tmux

# Development profile with VCS enhancement
set -g @forceline_profile 'development'
set -g @forceline_vcs_integration 'enhanced'

# Rich status line for development workflow
set -g status-left "#{?client_prefix,#[fg=yellow]⌘ PREFIX#[default],#[fg=green]● NORMAL#[default]} #{session_name}:#{window_index}.#{pane_index} "
set -g status-right "#{E:FORCELINE_VCS_BRANCH} #{?#{m:*modified*,#{E:FORCELINE_VCS_STATUS}},#[fg=yellow]±,}#{?#{m:*ahead*,#{E:FORCELINE_VCS_STATUS}},#[fg=blue]↑,}#[default] | #{E:FORCELINE_CPU_PERCENTAGE} #{E:FORCELINE_MEMORY_PERCENTAGE} | #{s|$HOME|~|:pane_current_path} | #{T:%H:%M}"

# Enhanced modules for development
set -g @forceline_directory_git_detection 'true'
set -g @forceline_vcs_show_symbols 'true'
```

### Server Administration
```bash
# ~/.tmux.conf for server admin
run-shell ~/.tmux/plugins/tmux-forceline/forceline.tmux

# Server profile for headless systems
set -g @forceline_profile 'server'

# System health focused status line
set -g status-left "#{host_short} UP:#{E:FORCELINE_UPTIME_COMPACT} "
set -g status-right "#{?#{E:FORCELINE_LOAD_CRITICAL},#[fg=red]CRIT,#{?#{E:FORCELINE_LOAD_HIGH},#[fg=yellow]HIGH,#[fg=green]OK}}:#{E:FORCELINE_LOAD_CURRENT}#[default] MEM:#{?#{E:FORCELINE_MEMORY_HIGH},#[fg=red],#[fg=green]}#{E:FORCELINE_MEMORY_PERCENTAGE}#[default] #{T:%H:%M %Z}"

# Minimal visual complexity for server environments
set -g @forceline_visual_complexity 'minimal'
set -g @forceline_icons 'none'
set -g @forceline_color_scheme 'monochrome'
```

---

These examples demonstrate the power and flexibility of tmux-forceline v3.0, showcasing how the native format integration and intelligent adaptation system can be configured for any use case while maintaining optimal performance.