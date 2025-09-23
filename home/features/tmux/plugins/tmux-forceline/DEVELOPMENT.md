# tmux-forceline Development Guide

## 🚀 Quick Start with Dev Container

The fastest way to start developing tmux-forceline is using the provided development container:

### Prerequisites
- Docker or Podman
- VS Code with Remote-Containers extension

### Getting Started

1. **Clone and Open in Container**:
   ```bash
   git clone <repository-url>
   cd tmux-forceline
   code .
   ```

2. **Open in Dev Container**:
   - Press `F1` → "Remote-Containers: Reopen in Container"
   - Or click the green corner button → "Reopen in Container"

3. **Start Development Environment**:
   ```bash
   start_dev_env
   ```

The dev container includes everything needed:
- ✅ tmux 3.3+ with all dependencies
- ✅ Shell scripting tools (shellcheck, shfmt, bats)
- ✅ Enterprise development tools
- ✅ Monitoring and security frameworks
- ✅ Package building tools
- ✅ Documentation generators

## 📁 Project Structure

```
tmux-forceline/
├── .devcontainer/           # Development container configuration
│   ├── devcontainer.json    # Container and VS Code settings
│   ├── Dockerfile           # Development environment image
│   ├── post-create.sh       # Initial setup script
│   └── post-start.sh        # Container startup script
├── enterprise/              # Enterprise features (Phase 7)
│   ├── config_manager.sh    # Configuration management
│   ├── security_hardening.sh # Security framework
│   ├── monitoring_observability.sh # Monitoring suite
│   └── deployment_automation.sh # Deployment tools
├── modules/                 # Core status bar modules
├── plugins/                 # Plugin ecosystem
├── themes/                  # Theme system
├── utils/                   # Utility functions
├── tests/                   # Testing framework
│   ├── unit/                # Unit tests
│   ├── integration/         # Integration tests
│   ├── performance/         # Performance tests
│   └── enterprise/          # Enterprise feature tests
├── scripts/                 # Development scripts
│   ├── dev-build.sh         # Development build
│   ├── dev-test.sh          # Test runner
│   └── dev-server.sh        # Development server
├── docs/                    # Documentation
├── forceline.tmux           # Main executable
├── tmux-forceline-cli.sh    # CLI interface
└── DEVELOPMENT.md           # This file
```

## 🛠️ Development Workflow

### 1. Environment Setup

**Using Dev Container (Recommended)**:
```bash
# Container automatically sets up everything
start_dev_env  # Starts tmux development session
```

**Manual Setup**:
```bash
# Install dependencies
sudo apt-get install tmux shellcheck bats bc

# Set environment variables
export FORCELINE_DEV=true
export FORCELINE_DIR="$(pwd)"

# Initialize enterprise components
./enterprise/config_manager.sh init development
```

### 2. Development Commands

```bash
# Navigate to project
fl                          # Alias for cd $FORCELINE_DIR

# Testing
flt                        # Run all tests
./scripts/dev-test.sh      # Comprehensive test runner
bats tests/unit/           # Run specific test suite

# Building
flb                        # Build and validate
./scripts/dev-build.sh     # Full development build

# Performance
performance-test           # Run performance benchmarks
fld                       # Show performance dashboard

# Security
security-scan             # Run security analysis
security-scan /path/plugin # Scan specific plugin

# Monitoring  
monitoring-start          # Start monitoring services
./scripts/dev-server.sh   # Start dev server with monitoring
```

### 3. Code Quality

All code must pass quality checks:

```bash
# Shell script linting
shellcheck **/*.sh

# Markdown linting
markdownlint-cli2 "**/*.md"

# Format shell scripts
shfmt -w **/*.sh

# Test coverage
bats tests/ --coverage
```

Pre-commit hooks automatically run these checks.

### 4. Testing Strategy

**Unit Tests** (`tests/unit/`):
- Test individual functions and modules
- Mock external dependencies
- Fast execution (<1s per test)

**Integration Tests** (`tests/integration/`):
- Test module interactions
- Real tmux session testing
- End-to-end workflows

**Performance Tests** (`tests/performance/`):
- Benchmark critical paths
- Validate performance requirements
- Regression detection

**Enterprise Tests** (`tests/enterprise/`):
- Security framework validation
- Compliance testing
- Deployment automation

### 5. Performance Development

tmux-forceline follows the "Tao of Tmux" philosophy:

```bash
# Native format examples (zero shell overhead)
"#{session_name}"           # Instead of $(tmux display-message -p '#S')
"#{host_short}"             # Instead of $(hostname -s)
"#{T:%H:%M:%S}"            # Instead of $(date +%H:%M:%S)

# Conditional formatting (massive performance gain)
"#{?client_prefix,#[fg=yellow]⌘,#[fg=green]●}#[default]"

# Environment variable integration
"#{E:FORCELINE_LOAD_CURRENT}"

# Path manipulation
"#{s|$HOME|~|:pane_current_path}"
"#{b:pane_current_path}"
```

**Performance Requirements**:
- Status update: <100ms (target: <50ms)
- Memory usage: <50MB
- Plugin execution: <100ms
- Cache efficiency: >90% hit rate

### 6. Enterprise Development

Enterprise features are modular and environment-aware:

```bash
# Configuration management
./enterprise/config_manager.sh init corporate
./enterprise/config_manager.sh apply-compliance sox,hipaa

# Security hardening
./enterprise/security_hardening.sh apply high_security
./enterprise/security_hardening.sh scan

# Monitoring setup
./enterprise/monitoring_observability.sh init
./enterprise/monitoring_observability.sh dashboard performance

# Deployment automation
./enterprise/deployment_automation.sh package all
./enterprise/deployment_automation.sh deploy staged development
```

## 🧪 Testing Framework

### Running Tests

```bash
# All tests
./scripts/dev-test.sh

# Specific test suites
bats tests/unit/basic_functionality.bats
bats tests/integration/module_integration.bats
bats tests/performance/native_performance.bats
bats tests/enterprise/security_framework.bats

# Test with coverage
bats --coverage tests/

# Performance regression testing
./enterprise/performance/performance_benchmark.sh
```

### Writing Tests

**Unit Test Example**:
```bash
#!/usr/bin/env bats

setup() {
    export FORCELINE_DIR="$PWD"
    export FORCELINE_DEV="true"
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
}

@test "native format conversion works correctly" {
    source modules/datetime/datetime_native.sh
    
    run get_native_datetime_format "time"
    assert_success
    assert_output "#{T:%H:%M:%S}"
}
```

**Integration Test Example**:
```bash
@test "status bar updates successfully" {
    # Start test tmux session
    tmux new-session -d -s test_session
    
    # Apply forceline configuration
    tmux source-file forceline_tmux.conf
    
    # Verify status bar is working
    run tmux display-message -p "#{status-left}"
    assert_success
    refute_output ""
    
    # Cleanup
    tmux kill-session -t test_session
}
```

### Performance Testing

```bash
# Measure status update time
measure_update_time() {
    local start_time=$(date +%s%N)
    tmux refresh-client -S
    local end_time=$(date +%s%N)
    echo $(( (end_time - start_time) / 1000000 ))  # ms
}

@test "status update completes within 100ms" {
    local update_time=$(measure_update_time)
    [[ $update_time -lt 100 ]]
}
```

## 🏗️ Building and Packaging

### Development Build

```bash
./scripts/dev-build.sh
```

This runs:
1. Shell script validation (shellcheck)
2. Markdown linting
3. Unit and integration tests
4. Performance validation
5. Enterprise feature checks

### Package Building

```bash
# Build all packages
./enterprise/deployment_automation.sh package all

# Build specific packages
./enterprise/deployment_automation.sh package deb
./enterprise/deployment_automation.sh package rpm

# Build container images
./enterprise/deployment_automation.sh container docker
```

### Release Process

1. **Version Bump**:
   ```bash
   # Update version in forceline.tmux
   sed -i 's/VERSION="[^"]*"/VERSION="3.1.0"/' forceline.tmux
   ```

2. **Full Testing**:
   ```bash
   ./scripts/dev-test.sh
   ./enterprise/performance/performance_benchmark.sh
   ```

3. **Package Build**:
   ```bash
   ./enterprise/deployment_automation.sh package all
   ```

4. **Documentation Update**:
   ```bash
   # Update COMPLETION_SUMMARY.md
   # Update CHANGELOG.md
   ```

5. **Git Tag**:
   ```bash
   git tag -a v3.1.0 -m "Release v3.1.0"
   git push origin v3.1.0
   ```

## 🔧 VS Code Integration

The dev container includes extensive VS Code integration:

### Extensions Included
- **Shell Scripting**: shellcheck, shell-format, bash-ide
- **Documentation**: markdown-all-in-one, markdownlint
- **Git**: GitLens, GitHub integration
- **Testing**: Test Explorer, Code Runner
- **Containers**: Docker extension

### Tasks Available
- **Build Development** (`Ctrl+Shift+P` → "Tasks: Run Task")
- **Run Tests**
- **Start Development Server**
- **Performance Benchmark**
- **Security Scan**

### Debugging
- Launch configuration for debugging tmux-forceline scripts
- Integrated terminal with development environment
- Real-time error detection and linting

## 🚀 Advanced Development

### Plugin Development

Create new plugins following the SDK:
```bash
# Generate plugin template
./ecosystem/plugin_manager.sh create my-plugin

# Validate plugin performance
./ecosystem/plugin_manager.sh validate ./plugins/my-plugin/

# Install for testing
./ecosystem/plugin_manager.sh install ./plugins/my-plugin/
```

### Theme Development

Create custom themes:
```bash
# Generate theme template
./themes/theme_manager.sh create my-theme

# Apply for testing
./themes/theme_manager.sh apply my-theme

# Validate theme compatibility
./themes/theme_manager.sh validate my-theme
```

### Enterprise Feature Development

Add new enterprise capabilities:
```bash
# Configuration management extension
./enterprise/config_manager.sh extend my-feature

# Security policy creation
./enterprise/security_hardening.sh create-policy my-policy

# Monitoring metric addition
./enterprise/monitoring_observability.sh add-metric my-metric
```

## 🌐 Deployment Testing

### Local Deployment Testing

```bash
# Test single host deployment
./enterprise/deployment_automation.sh deploy single development localhost

# Test container deployment
./enterprise/deployment_automation.sh container docker

# Test Kubernetes deployment
./enterprise/deployment_automation.sh container kubernetes
```

### Multi-Environment Testing

```bash
# Staged deployment testing
./enterprise/deployment_automation.sh orchestrate pipeline development,staging

# Rolling deployment testing
./enterprise/deployment_automation.sh orchestrate rolling staging

# Canary deployment testing
./enterprise/deployment_automation.sh orchestrate canary production
```

## 📊 Performance Profiling

### Profiling Tools

```bash
# Shell script profiling
bash -x forceline.tmux status 2>&1 | grep +

# Performance benchmarking
./enterprise/performance/performance_benchmark.sh detailed

# Memory profiling
valgrind --tool=massif bash forceline.tmux status

# System call tracing
strace -c bash forceline.tmux status
```

### Performance Optimization

1. **Use Native Formats**: Always prefer `#{variable}` over `$(command)`
2. **Cache Expensive Operations**: Use background updates for slow data
3. **Minimize Shell Processes**: Combine operations where possible
4. **Optimize Critical Path**: Status update must be <100ms
5. **Profile Regularly**: Use continuous performance monitoring

## 🔒 Security Development

### Security Testing

```bash
# Full security scan
./enterprise/security_hardening.sh scan

# Vulnerability assessment
./enterprise/security_hardening.sh report

# Plugin security validation
./enterprise/security_hardening.sh scan /path/to/plugin
```

### Security Guidelines

1. **Input Validation**: Sanitize all external inputs
2. **Privilege Minimization**: Run with least required permissions
3. **Secure Defaults**: All security features enabled by default
4. **Audit Logging**: Log all security-relevant operations
5. **Regular Updates**: Keep dependencies updated

## 📚 Documentation Development

### Documentation Structure

```bash
docs/
├── installation/           # Installation guides
├── configuration/         # Configuration documentation
├── enterprise/           # Enterprise feature docs
├── api/                 # API documentation
├── tutorials/           # Step-by-step guides
└── troubleshooting/     # Common issues and solutions
```

### Documentation Tools

```bash
# Serve documentation locally
./scripts/dev-server.sh     # Includes docs on port 8080

# Check documentation links
markdown-link-check docs/**/*.md

# Generate API docs
./scripts/generate-api-docs.sh

# Build documentation site
./scripts/build-docs.sh
```

## 🤝 Contributing

### Code Style

- **Shell Scripts**: Follow Google Shell Style Guide
- **Configuration**: Use consistent YAML/TOML formatting  
- **Documentation**: Use clear, concise markdown
- **Git Commits**: Use conventional commit format

### Pull Request Process

1. **Fork and Branch**: Create feature branch from main
2. **Develop**: Use dev container for consistent environment
3. **Test**: All tests must pass (`./scripts/dev-test.sh`)
4. **Document**: Update relevant documentation
5. **Review**: Submit PR for code review
6. **Merge**: Squash and merge after approval

### Issue Reporting

Use GitHub issue templates:
- **Bug Report**: Include reproduction steps and environment
- **Feature Request**: Describe use case and proposed solution
- **Security Issue**: Use security@tmux-forceline.org for sensitive issues

## 📞 Getting Help

- **Documentation**: Check docs/ directory first
- **Development Guide**: This file for development questions
- **Community**: GitHub Discussions for general questions
- **Issues**: GitHub Issues for bugs and feature requests
- **Security**: security@tmux-forceline.org for security concerns

---

Happy developing! 🚀 The tmux-forceline development environment is designed to make contributing as smooth and productive as possible.