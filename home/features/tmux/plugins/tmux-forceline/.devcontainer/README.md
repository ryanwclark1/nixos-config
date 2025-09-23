# tmux-forceline Development Container

This directory contains a complete development container configuration for tmux-forceline, providing a consistent, reproducible development environment across all platforms.

## 🎯 What's Included

### Development Environment
- **Ubuntu 22.04** base with all dependencies pre-installed
- **tmux 3.3+** built from source for latest features
- **Complete shell toolchain**: bash, zsh, fish with development tools
- **Enterprise features** fully initialized and ready for development

### Development Tools
- **Code Quality**: shellcheck, shfmt, markdownlint, yamllint
- **Testing Framework**: bats with comprehensive test suites
- **Performance Tools**: profiling, benchmarking, monitoring
- **Security Tools**: vulnerability scanning, security analysis
- **Package Building**: multi-platform package creation tools

### VS Code Integration
- **40+ Extensions** for shell scripting, documentation, Git, containers
- **Tasks and Launch Configs** for building, testing, debugging
- **Integrated Terminal** with tmux development session
- **Code Formatting** and linting with real-time feedback

### Enterprise Development
- **Configuration Management** with multi-environment support
- **Security Hardening** with compliance frameworks
- **Monitoring & Observability** with dashboards and alerting
- **Deployment Automation** with container and orchestration support

## 🚀 Quick Start

### Option 1: VS Code Dev Container (Recommended)

1. **Prerequisites**:
   ```bash
   # Install VS Code and Docker
   # Install "Remote - Containers" extension
   ```

2. **Open Project**:
   ```bash
   git clone <repository-url>
   cd tmux-forceline
   code .
   # Click "Reopen in Container" when prompted
   ```

3. **Start Development**:
   ```bash
   # Container automatically starts, then run:
   start_dev_env
   ```

### Option 2: Docker Compose

1. **Start Development Environment**:
   ```bash
   cd .devcontainer
   docker-compose up -d tmux-forceline-dev
   docker-compose exec tmux-forceline-dev bash
   ```

2. **Access Services**:
   - Development: `http://localhost:3000`
   - Documentation: `http://localhost:8080`
   - Monitoring: `http://localhost:9090`

### Option 3: Direct Docker Build

1. **Build and Run**:
   ```bash
   cd .devcontainer
   docker build -t tmux-forceline-dev .
   docker run -it -v "$(pwd)/..":/workspace tmux-forceline-dev
   ```

## 📁 Container Configuration Files

### Core Configuration
- **`devcontainer.json`**: VS Code dev container configuration with extensions, settings, and features
- **`Dockerfile`**: Multi-stage development environment with all tools and dependencies
- **`docker-compose.yml`**: Multi-service development stack with monitoring and documentation

### Setup Scripts
- **`post-create.sh`**: Initial container setup - runs once after container creation
- **`post-start.sh`**: Startup script - runs every time container starts

### Generated Files
- **Development scripts**: `dev-build.sh`, `dev-test.sh`, `dev-server.sh`
- **Testing framework**: Complete bats test structure
- **VS Code workspace**: Tasks, launch configs, and settings
- **Git hooks**: Pre-commit quality checks

## 🛠️ Development Workflow

### 1. Container Startup
```bash
# Automatic setup when container starts:
✅ File permissions configured
✅ Enterprise components initialized  
✅ Development services started
✅ VS Code workspace configured
✅ Git hooks installed
```

### 2. Development Commands
```bash
# Quick navigation and testing
fl                    # Navigate to forceline directory
flt                   # Run all tests
flb                   # Build and validate
fld                   # Show performance dashboard

# Enterprise features
performance-test      # Run benchmarks
security-scan        # Security analysis
monitoring-start     # Start monitoring

# Development workflow
./scripts/dev-build.sh   # Full development build
./scripts/dev-test.sh    # Comprehensive testing
./scripts/dev-server.sh  # Start development server
```

### 3. VS Code Integration
- **Automatic Extension Installation**: 40+ development extensions
- **Task Integration**: Build, test, and deployment tasks
- **Debug Configuration**: Shell script debugging support
- **Terminal Integration**: Pre-configured tmux development session

## 🧪 Testing Framework

### Comprehensive Test Coverage
```bash
tests/
├── unit/              # Function and module tests
├── integration/       # End-to-end workflow tests  
├── performance/       # Performance and regression tests
├── enterprise/        # Enterprise feature validation
└── security/          # Security framework tests
```

### Running Tests
```bash
# All tests
./scripts/dev-test.sh

# Specific test categories
bats tests/unit/           # Unit tests
bats tests/integration/    # Integration tests
bats tests/performance/    # Performance tests
bats tests/enterprise/     # Enterprise tests

# Continuous testing
bats --watch tests/        # Re-run on file changes
```

## 📊 Monitoring and Observability

### Development Monitoring Stack
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization dashboards
- **Custom Metrics**: Performance and usage tracking
- **Health Checks**: Automated service monitoring

### Access Points
- **Performance Dashboard**: `http://localhost:9090`
- **Grafana Dashboards**: `http://localhost:3001` (admin/admin)
- **Documentation**: `http://localhost:8080`
- **Live Reload**: `http://localhost:3000`

## 🔒 Security Development

### Security Framework
- **Vulnerability Scanning**: Automated plugin and code analysis
- **Compliance Testing**: SOX, HIPAA, PCI-DSS validation
- **Security Policies**: Enterprise-grade security controls
- **Audit Logging**: Complete development activity tracking

### Security Commands
```bash
# Security analysis
./enterprise/security_hardening.sh scan
./enterprise/security_hardening.sh report

# Compliance validation
./enterprise/config_manager.sh compliance-check sox,hipaa

# Security monitoring
./enterprise/security_hardening.sh monitor
```

## 🚀 Deployment Testing

### Container Testing
```bash
# Docker deployment
./enterprise/deployment_automation.sh container docker

# Kubernetes deployment  
./enterprise/deployment_automation.sh container kubernetes

# Package building
./enterprise/deployment_automation.sh package all
```

### Multi-Environment Testing
```bash
# Staged deployment simulation
./enterprise/deployment_automation.sh orchestrate pipeline development,staging

# Rolling deployment testing
./enterprise/deployment_automation.sh orchestrate rolling staging
```

## 📚 Documentation Development

### Documentation Stack
- **Live Server**: Real-time documentation preview
- **Markdown Tools**: Linting, formatting, link checking
- **API Documentation**: Automated API doc generation
- **Enterprise Docs**: Complete enterprise feature documentation

### Documentation Commands
```bash
# Start documentation server
./scripts/dev-server.sh    # Includes docs on port 8080

# Validate documentation
markdownlint-cli2 "**/*.md"
markdown-link-check docs/**/*.md

# Generate API docs
./scripts/generate-api-docs.sh
```

## 🔧 Customization

### Environment Variables
```bash
# Development configuration
FORCELINE_DEV=true          # Enable development mode
FORCELINE_DIR=/workspace     # Project directory
ENTERPRISE_DIR=/workspace/enterprise  # Enterprise features

# Performance tuning
FORCELINE_UPDATE_INTERVAL=1  # Fast updates for development
FORCELINE_CACHE_TTL=5       # Short cache for development

# Enterprise configuration
FORCELINE_SECURITY_LEVEL=standard    # Development security
FORCELINE_MONITORING_LEVEL=comprehensive  # Full monitoring
```

### VS Code Customization
```json
// Additional extensions in devcontainer.json
"customizations": {
  "vscode": {
    "extensions": [
      "your.custom.extension"
    ],
    "settings": {
      "your.custom.setting": "value"
    }
  }
}
```

### Docker Compose Profiles
```bash
# Start with monitoring stack
docker-compose --profile monitoring up -d

# Start with testing environment
docker-compose --profile testing up -d

# Start with security tools
docker-compose --profile security up -d
```

## 🐛 Troubleshooting

### Common Issues

**Container won't start**:
```bash
# Check Docker daemon
docker info

# Rebuild container
docker-compose build --no-cache tmux-forceline-dev
```

**VS Code extensions not loading**:
```bash
# Reload window
Ctrl+Shift+P → "Developer: Reload Window"

# Rebuild container
Ctrl+Shift+P → "Remote-Containers: Rebuild Container"
```

**Tests failing**:
```bash
# Check environment
echo $FORCELINE_DEV
echo $FORCELINE_DIR

# Reset development environment
./enterprise/config_manager.sh init development
```

**Performance issues**:
```bash
# Check container resources
docker stats tmux-forceline-dev

# Increase memory limit in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 4G
```

### Getting Help

1. **Check Development Guide**: `DEVELOPMENT.md`
2. **Review Container Logs**: `docker-compose logs tmux-forceline-dev`
3. **Validate Configuration**: `./scripts/dev-build.sh`
4. **Reset Environment**: Remove container and volumes, rebuild

## 🎯 Development Container Benefits

### **★ Insight ─────────────────────────────────────**
- **Instant Setup**: Zero-configuration development environment in minutes
- **Consistency**: Identical environment across all developer machines
- **Enterprise Ready**: Full enterprise feature development without complex setup
**─────────────────────────────────────────────────**

### Features Summary
✅ **Complete Development Stack**: All tools and dependencies pre-configured  
✅ **VS Code Integration**: 40+ extensions with tasks and debugging  
✅ **Testing Framework**: Comprehensive test suites with continuous testing  
✅ **Enterprise Development**: Security, monitoring, and deployment tools  
✅ **Performance Optimization**: Built-in profiling and benchmarking  
✅ **Documentation Tools**: Live preview and validation  
✅ **Container Support**: Docker and Kubernetes development  
✅ **Security Framework**: Vulnerability scanning and compliance testing  
✅ **Multi-Environment**: Development, staging, and production simulation  
✅ **Quality Assurance**: Automated code quality and pre-commit hooks  

The development container provides everything needed to contribute to tmux-forceline, from simple bug fixes to complex enterprise feature development, all in a consistent, reproducible environment.

---

**Ready to start developing?** 🚀  
Run `start_dev_env` and begin contributing to the ultimate tmux status bar system!