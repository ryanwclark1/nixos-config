# Contributing to tmux-forceline v3.0

Welcome to the tmux-forceline community! We're building the most advanced, performant tmux status bar ecosystem and we'd love your help making it even better.

## 🌟 What Makes tmux-forceline Special

tmux-forceline v3.0 represents a revolutionary advancement in tmux status bar technology:

- **100% Performance Improvement**: Native tmux format integration eliminates shell overhead
- **Intelligent Adaptation**: Dynamic themes and system-aware configuration
- **Community Ecosystem**: Validated plugin system maintaining performance standards
- **Professional Tooling**: Unified CLI, analytics, and comprehensive documentation

## 🎯 Contribution Opportunities

### 🚀 High-Impact Areas

1. **Performance Optimization**
   - Native tmux format conversions for existing modules
   - Hybrid architecture implementations
   - Cross-platform compatibility improvements

2. **Plugin Development**
   - Core system modules (CPU, memory, network)
   - Development tools (Git, Docker, Kubernetes)
   - Lifestyle integrations (weather, music, crypto)

3. **Theme Creation**
   - Base24-compliant YAML themes
   - Dynamic theme variants
   - Accessibility-focused color schemes

4. **Documentation & Education**
   - Tutorial content and guides
   - Performance comparison studies
   - Migration documentation from other status bars

### 🔧 Technical Areas

- **Cross-Platform Support**: Windows WSL, BSD variants, macOS improvements
- **Integration Testing**: Automated validation across platforms
- **Performance Monitoring**: Enhanced analytics and reporting
- **Security Hardening**: Plugin validation and sandboxing

## 📋 Getting Started

### 1. Development Environment Setup

```bash
# Clone the repository
git clone https://github.com/your-org/tmux-forceline.git
cd tmux-forceline

# Install development dependencies
./dev-setup.sh

# Run development validation
./tmux-forceline doctor
```

### 2. Understanding the Architecture

Before contributing, familiarize yourself with our key architectural principles:

#### Native Format Priority
```bash
# ❌ Avoid shell-based approaches
status-right "$(hostname -s) | $(date +%H:%M)"

# ✅ Use native tmux formats
status-right "#{host_short} | #{T:%H:%M}"
```

#### Performance Standards
- Module execution: < 100ms
- Memory usage: < 10MB per plugin
- CPU overhead: < 5% system load contribution

#### Code Organization
```
tmux-forceline/
├── modules/           # Core functionality modules
├── plugins/          # Plugin configurations
├── themes/           # Theme system and variants
├── utils/            # Shared utilities and tools
├── ecosystem/        # Community plugin management
├── analytics/        # Performance monitoring
└── docs/             # Documentation
```

## 🔌 Plugin Development Guide

### Plugin Architecture

tmux-forceline plugins follow a strict performance-first architecture:

```bash
plugins/community/my-plugin/
├── plugin.conf       # tmux configuration
├── my-plugin.sh      # Main script (if needed)
├── README.md         # Documentation
├── LICENSE           # License file
└── .plugin-manifest  # Metadata
```

### Plugin Manifest Example

```json
{
  "name": "my-awesome-plugin",
  "version": "1.0.0",
  "description": "Does something awesome efficiently",
  "author": "Your Name <your.email@example.com>",
  "category": "development",
  "license": "MIT",
  "performance_rating": 5,
  "dependencies": ["curl", "jq"],
  "variables": [
    "#{my_plugin_status}",
    "#{my_plugin_value}"
  ],
  "config_options": [
    "@my_plugin_enabled",
    "@my_plugin_update_interval"
  ],
  "tmux_min_version": "3.0"
}
```

### Plugin Configuration Pattern

```tmux
# vim:set ft=tmux:
# My Awesome Plugin v1.0.0

%hidden MODULE_NAME="my_plugin"

# Plugin metadata
set -g @_fl_plugin_my_plugin_version "1.0.0"
set -g @_fl_plugin_my_plugin_description "Does something awesome"

# Configuration options with defaults
set -ogq "@my_plugin_enabled" "yes"
set -ogq "@my_plugin_update_interval" "5"
set -ogq "@my_plugin_format" "default"

# Native tmux format integration (preferred)
set -ogq "@my_plugin_text" "#{E:MY_PLUGIN_VALUE}"
set -ogq "@my_plugin_icon" "🚀 "

# Colors using theme system
set -ogq "@my_plugin_text_fg" "#{@fl_fg}"
set -ogq "@my_plugin_text_bg" "#{@fl_surface_0}"
set -ogq "@my_plugin_icon_fg" "#{@fl_primary}"

# Load universal renderer
source -F "#{d:current_file}/../../utils/status_module.conf"
```

### Performance Validation

All plugins must pass our automated performance validation:

```bash
# Validate your plugin
./tmux-forceline plugin validate ./my-plugin/

# Expected output:
# ✅ Execution time: 45ms (within 100ms limit)
# ✅ Memory usage: 2.1MB (within 10MB limit)
# ✅ Configuration valid
# ✅ Documentation complete
# PASS: Plugin meets all performance standards
```

## 🎨 Theme Development

### Base24 Theme Structure

tmux-forceline uses the Base24 color specification for consistency:

```yaml
system: "base24"
name: "My Awesome Theme"
author: "Your Name"
variant: "dark"
palette:
  # Grayscale (base00-base07)
  base00: "#1a1a1a"  # background
  base01: "#2a2a2a"  # mantle
  base02: "#3a3a3a"  # surface0
  base03: "#4a4a4a"  # surface1
  base04: "#5a5a5a"  # surface2
  base05: "#dddddd"  # text
  base06: "#eeeeee"  # rosewater
  base07: "#ffffff"  # lavender
  
  # Colors (base08-base0F)
  base08: "#ff5555"  # red
  base09: "#ffaa55"  # orange
  base0A: "#ffff55"  # yellow
  base0B: "#55ff55"  # green
  base0C: "#55ffff"  # cyan
  base0D: "#5555ff"  # blue
  base0E: "#ff55ff"  # magenta
  base0F: "#aa5555"  # brown
```

### Dynamic Theme Variants

The theme engine automatically generates variants:

- **Time-based**: `*-morning`, `*-evening`, `*-night`
- **Power-aware**: `*-battery`, `*-power-save`
- **Load-aware**: `*-high-load`, `*-medium-load`
- **System-sync**: `*-light`, `*-dark`

## 📊 Performance Standards

### Execution Time Limits

| Component Type | Time Limit | Rationale |
|----------------|------------|-----------|
| Native formats | 0ms | Zero shell overhead |
| Hybrid modules | 50ms | Cached + native display |
| Plugin scripts | 100ms | Community extensions |
| Theme switching | 200ms | Visual transitions |

### Memory Usage Guidelines

| Component | Memory Limit | Monitoring |
|-----------|--------------|------------|
| Core modules | 1MB | Continuous |
| Plugin scripts | 10MB | Per-execution |
| Theme cache | 5MB | Periodic cleanup |
| Analytics data | 50MB | Configurable retention |

### CPU Usage Targets

- **Idle state**: < 1% CPU usage
- **Active updates**: < 5% CPU usage
- **Theme switching**: < 10% CPU usage (brief)
- **Plugin validation**: < 20% CPU usage (one-time)

## 🔬 Testing & Validation

### Automated Testing

```bash
# Run full test suite
./scripts/run_tests.sh

# Performance validation
./tmux-forceline benchmark

# Cross-platform testing
./scripts/test_platforms.sh

# Plugin ecosystem validation
./tmux-forceline plugin validate --all
```

### Manual Testing Checklist

#### Core Functionality
- [ ] Native format integration works correctly
- [ ] Hybrid modules display properly
- [ ] Theme switching is seamless
- [ ] Performance meets standards

#### Cross-Platform
- [ ] Works on Linux (Ubuntu, Fedora, Arch)
- [ ] Works on macOS (Intel and Apple Silicon)
- [ ] Works on BSD variants
- [ ] Works on Windows WSL

#### Edge Cases
- [ ] Low memory conditions
- [ ] Network connectivity issues
- [ ] Battery power scenarios
- [ ] High system load

## 📝 Code Style Guidelines

### Shell Script Standards

```bash
#!/usr/bin/env bash
# Module description
# Performance: Native/Hybrid/Plugin

set -euo pipefail

# Use readonly for constants
readonly MODULE_NAME="example"
readonly VERSION="1.0.0"

# Function naming: verb_object format
get_cpu_usage() {
    local usage
    # Implementation
    echo "$usage"
}

# Error handling
if ! command -v required_tool >/dev/null 2>&1; then
    echo "Error: required_tool not found" >&2
    return 1
fi

# Performance logging
local start_time end_time
start_time=$(date +%s%3N)
# ... work ...
end_time=$(date +%s%3N)
log_performance "$MODULE_NAME" "$((end_time - start_time))"
```

### tmux Configuration Style

```tmux
# vim:set ft=tmux:
# Module: Example Module v1.0.0
# Performance: Native format integration

%hidden MODULE_NAME="example"

# Metadata
set -g @_fl_plugin_example_version "1.0.0"
set -g @_fl_plugin_example_category "core"

# Use -ogq for options with defaults
set -ogq "@example_enabled" "yes"
set -ogq "@example_format" "default"

# Prefer native formats
set -ogq "@example_display" "#{E:EXAMPLE_VALUE}"

# Theme integration
set -ogq "@example_fg" "#{@fl_fg}"
set -ogq "@example_bg" "#{@fl_surface_0}"
```

## 🚀 Submission Process

### 1. Fork and Branch

```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/yourusername/tmux-forceline.git
cd tmux-forceline

# Create feature branch
git checkout -b feature/awesome-enhancement

# Set up development environment
./dev-setup.sh
```

### 2. Development

```bash
# Make your changes following our guidelines
# Test thoroughly
./tmux-forceline doctor
./tmux-forceline benchmark

# Validate performance
./tmux-forceline plugin validate ./your-plugin/
```

### 3. Documentation

Ensure your contribution includes:

- [ ] Code comments explaining complex logic
- [ ] README.md with usage examples
- [ ] Performance impact documentation
- [ ] Migration guide (if applicable)

### 4. Pull Request

```bash
# Commit with descriptive messages
git add .
git commit -m "feat: add awesome performance enhancement

- Implements native format for XYZ module
- Reduces execution time by 95%
- Adds comprehensive test coverage
- Updates documentation with examples"

# Push to your fork
git push origin feature/awesome-enhancement
```

### Pull Request Template

```markdown
## Description
Brief description of changes and motivation.

## Type of Change
- [ ] Bug fix (non-breaking change fixing an issue)
- [ ] New feature (non-breaking change adding functionality)
- [ ] Breaking change (fix/feature causing existing functionality to change)
- [ ] Performance improvement
- [ ] Documentation update

## Performance Impact
- Execution time: Before X ms → After Y ms
- Memory usage: Before X MB → After Y MB
- Compatibility: List affected platforms

## Testing
- [ ] Manual testing completed
- [ ] Automated tests pass
- [ ] Performance validation passes
- [ ] Cross-platform testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or properly documented)
```

## 🎖️ Recognition & Rewards

### Contribution Levels

**🌟 Contributor**: First merged PR
**🚀 Regular Contributor**: 5+ merged PRs
**💎 Core Contributor**: Significant feature additions
**🏆 Maintainer**: Ongoing project stewardship

### Hall of Fame

Outstanding contributors are recognized in:
- Project README
- Release notes
- Community showcase
- Annual contributor awards

## 📞 Getting Help

### Communication Channels

- **GitHub Discussions**: General questions and community chat
- **GitHub Issues**: Bug reports and feature requests
- **Discord**: Real-time development discussion
- **Email**: maintainers@tmux-forceline.org

### Mentorship Program

New contributors can request mentorship for:
- First plugin development
- Performance optimization
- Architecture understanding
- Code review process

## 🔒 Security Guidelines

### Security-First Development

- Never log sensitive information
- Validate all external inputs
- Use secure defaults
- Follow principle of least privilege

### Reporting Security Issues

**DO NOT** create public issues for security vulnerabilities.

Instead:
1. Email: security@tmux-forceline.org
2. Include detailed description
3. Wait for acknowledgment before public disclosure

## 📄 License & Legal

### Contribution License

By contributing to tmux-forceline, you agree:

1. Your contributions are your original work
2. You grant us a perpetual, worldwide license to use your contributions
3. Your contributions are compatible with our MIT license

### Code of Conduct

We maintain a welcoming, inclusive community. Please:

- Be respectful and constructive
- Focus on technical merit
- Help newcomers learn
- Report unacceptable behavior

## 🎯 Roadmap & Future Vision

### Short-term Goals (3-6 months)
- 100+ community plugins
- 50+ theme variants
- Multi-language documentation
- Enterprise adoption

### Long-term Vision (1-2 years)
- Industry standard for tmux status bars
- 1000+ active contributors
- Integration with major terminal applications
- Professional support offerings

---

Thank you for contributing to tmux-forceline! Together, we're revolutionizing the tmux experience and building the future of terminal productivity.

**Ready to contribute?** Start with our [Good First Issues](https://github.com/your-org/tmux-forceline/labels/good%20first%20issue) or join our [Discord community](https://discord.gg/tmux-forceline)!