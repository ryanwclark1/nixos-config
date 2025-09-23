#!/usr/bin/env bash

# tmux-forceline Development Container Post-Creation Setup
# This script runs after the container is created to set up the development environment

set -euo pipefail

echo "🔧 Setting up tmux-forceline development environment..."

# Ensure we're in the workspace directory
cd /workspace

# Set proper permissions
echo "📝 Setting file permissions..."
find . -name "*.sh" -type f -exec chmod +x {} \;
find . -name "*.tmux" -type f -exec chmod +x {} \;

# Initialize enterprise components if they exist
if [[ -d "enterprise" ]]; then
    echo "🏢 Initializing enterprise components..."
    
    # Initialize configuration management
    if [[ -f "enterprise/config_manager.sh" ]]; then
        ./enterprise/config_manager.sh init development
    fi
    
    # Initialize security framework
    if [[ -f "enterprise/security_hardening.sh" ]]; then
        ./enterprise/security_hardening.sh init
    fi
    
    # Initialize monitoring framework
    if [[ -f "enterprise/monitoring_observability.sh" ]]; then
        ./enterprise/monitoring_observability.sh init
    fi
    
    # Initialize deployment automation
    if [[ -f "enterprise/deployment_automation.sh" ]]; then
        ./enterprise/deployment_automation.sh init
    fi
fi

# Set up development configuration
echo "⚙️  Configuring development environment..."

# Create development-specific tmux configuration
mkdir -p ~/.config/tmux/forceline
cat > ~/.config/tmux/forceline/dev.conf << 'EOF'
# Development Configuration for tmux-forceline

# Enable development mode
set -g @fl_dev_mode "on"

# Reduced update intervals for development
set -g @fl_update_interval "1"
set -g @fl_cache_ttl "5"

# Enable all modules for testing
set -g @fl_battery_enabled "on"
set -g @fl_cpu_enabled "on"
set -g @fl_datetime_enabled "on"
set -g @fl_directory_enabled "on"
set -g @fl_hostname_enabled "on"
set -g @fl_load_enabled "on"
set -g @fl_memory_enabled "on"
set -g @fl_uptime_enabled "on"

# Development theme
set -g @fl_theme "development"

# Enable enterprise features in development
set -g @fl_enterprise_enabled "on"
set -g @fl_security_level "standard"
set -g @fl_monitoring_level "comprehensive"

# Development-specific colors
set -g @fl_dev_bg_color "#2d3748"
set -g @fl_dev_fg_color "#e2e8f0"
set -g @fl_dev_accent_color "#4fd1c7"
EOF

# Install development dependencies
echo "📦 Installing development dependencies..."

# Install testing framework (bats)
if ! command -v bats >/dev/null 2>&1; then
    echo "Installing bats testing framework..."
    git clone https://github.com/bats-core/bats-core.git /tmp/bats-core
    cd /tmp/bats-core
    sudo ./install.sh /usr/local
    cd /workspace
    rm -rf /tmp/bats-core
fi

# Install development tools
npm install -g \
    markdownlint-cli2 \
    markdown-link-check \
    doctoc

# Set up Git hooks for development
echo "🔗 Setting up Git hooks..."
mkdir -p .git/hooks

# Pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/usr/bin/env bash

# tmux-forceline pre-commit hook
# Runs quality checks before committing

echo "🔍 Running pre-commit checks..."

# Check shell scripts with shellcheck
echo "   Checking shell scripts..."
find . -name "*.sh" -type f | while read -r script; do
    if ! shellcheck "$script"; then
        echo "❌ Shellcheck failed for $script"
        exit 1
    fi
done

# Check markdown files
echo "   Checking markdown files..."
if command -v markdownlint-cli2 >/dev/null 2>&1; then
    if ! markdownlint-cli2 "**/*.md"; then
        echo "❌ Markdown lint failed"
        exit 1
    fi
fi

# Run tests if they exist
if [[ -d "tests" ]] && command -v bats >/dev/null 2>&1; then
    echo "   Running tests..."
    if ! bats tests/; then
        echo "❌ Tests failed"
        exit 1
    fi
fi

echo "✅ Pre-commit checks passed"
EOF

chmod +x .git/hooks/pre-commit

# Set up development scripts
echo "📋 Creating development scripts..."

# Development build script
cat > scripts/dev-build.sh << 'EOF'
#!/usr/bin/env bash

# Development build script for tmux-forceline

set -euo pipefail

echo "🏗️ Building tmux-forceline for development..."

# Validate all shell scripts
echo "📝 Validating shell scripts..."
find . -name "*.sh" -type f | while read -r script; do
    echo "   Checking $script..."
    shellcheck "$script"
done

# Run tests
if [[ -d "tests" ]]; then
    echo "🧪 Running tests..."
    bats tests/
fi

# Build documentation
if command -v markdown-cli >/dev/null 2>&1; then
    echo "📚 Building documentation..."
    # Add documentation build steps here
fi

# Performance validation
if [[ -f "enterprise/performance/performance_validation.sh" ]]; then
    echo "⚡ Running performance validation..."
    ./enterprise/performance/performance_validation.sh
fi

echo "✅ Development build completed successfully"
EOF

# Development test script
cat > scripts/dev-test.sh << 'EOF'
#!/usr/bin/env bash

# Development test runner for tmux-forceline

set -euo pipefail

echo "🧪 Running tmux-forceline development tests..."

# Unit tests
if [[ -d "tests/unit" ]]; then
    echo "🔬 Running unit tests..."
    bats tests/unit/
fi

# Integration tests
if [[ -d "tests/integration" ]]; then
    echo "🔗 Running integration tests..."
    bats tests/integration/
fi

# Performance tests
if [[ -d "tests/performance" ]]; then
    echo "⚡ Running performance tests..."
    bats tests/performance/
fi

# Enterprise tests
if [[ -d "tests/enterprise" ]]; then
    echo "🏢 Running enterprise tests..."
    bats tests/enterprise/
fi

# Security tests
if [[ -d "tests/security" ]]; then
    echo "🔒 Running security tests..."
    bats tests/security/
fi

echo "✅ All tests completed"
EOF

# Development server script
cat > scripts/dev-server.sh << 'EOF'
#!/usr/bin/env bash

# Development server for tmux-forceline documentation and monitoring

set -euo pipefail

echo "🌐 Starting tmux-forceline development server..."

# Start documentation server
if [[ -d "docs" ]]; then
    echo "📚 Starting documentation server on port 8080..."
    cd docs
    python3 -m http.server 8080 &
    DOC_SERVER_PID=$!
    cd ..
fi

# Start monitoring dashboard
if [[ -f "enterprise/monitoring_observability.sh" ]]; then
    echo "📊 Starting monitoring dashboard on port 9090..."
    ./enterprise/monitoring_observability.sh start &
    MONITOR_PID=$!
fi

# Start live reload for development
if command -v live-server >/dev/null 2>&1; then
    echo "🔄 Starting live reload server on port 3000..."
    live-server --port=3000 --host=0.0.0.0 &
    LIVE_SERVER_PID=$!
fi

echo "✅ Development servers started"
echo "   📚 Documentation: http://localhost:8080"
echo "   📊 Monitoring: http://localhost:9090"
echo "   🔄 Live Reload: http://localhost:3000"

# Wait for interrupt
trap 'echo "🛑 Stopping development servers..."; kill $DOC_SERVER_PID $MONITOR_PID $LIVE_SERVER_PID 2>/dev/null; exit 0' INT

wait
EOF

chmod +x scripts/dev-*.sh

# Create test directory structure
echo "🧪 Setting up test directory structure..."
mkdir -p tests/{unit,integration,performance,enterprise,security}

# Create sample test file
cat > tests/unit/basic_functionality.bats << 'EOF'
#!/usr/bin/env bats

# Basic functionality tests for tmux-forceline

setup() {
    export FORCELINE_DIR="$PWD"
    export FORCELINE_DEV="true"
}

@test "forceline.tmux exists and is executable" {
    [ -x "$FORCELINE_DIR/forceline.tmux" ]
}

@test "forceline.tmux responds to status command" {
    run "$FORCELINE_DIR/forceline.tmux" status
    [ "$status" -eq 0 ]
}

@test "enterprise components are available" {
    [ -d "$FORCELINE_DIR/enterprise" ]
    [ -f "$FORCELINE_DIR/enterprise/config_manager.sh" ]
    [ -f "$FORCELINE_DIR/enterprise/security_hardening.sh" ]
    [ -f "$FORCELINE_DIR/enterprise/monitoring_observability.sh" ]
    [ -f "$FORCELINE_DIR/enterprise/deployment_automation.sh" ]
}

@test "CLI tool is available" {
    [ -f "$FORCELINE_DIR/tmux-forceline-cli.sh" ]
    [ -x "$FORCELINE_DIR/tmux-forceline-cli.sh" ]
}
EOF

# Set up VS Code workspace settings
echo "⚙️  Configuring VS Code workspace..."
mkdir -p .vscode

cat > .vscode/settings.json << 'EOF'
{
  "files.associations": {
    "*.tmux": "shellscript",
    "*.conf": "properties",
    "*.policy": "properties",
    "*.profile": "properties"
  },
  "shellcheck.customArgs": [
    "-x"
  ],
  "shellformat.effectLanguages": [
    "shellscript",
    "dockerfile"
  ],
  "bats.testOnSave": true,
  "search.exclude": {
    "**/node_modules": true,
    "**/logs": true,
    "**/.cache": true
  },
  "terminal.integrated.env.linux": {
    "FORCELINE_DEV": "true",
    "FORCELINE_DIR": "/workspace"
  }
}
EOF

cat > .vscode/tasks.json << 'EOF'
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build Development",
      "type": "shell",
      "command": "./scripts/dev-build.sh",
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "problemMatcher": []
    },
    {
      "label": "Run Tests",
      "type": "shell",
      "command": "./scripts/dev-test.sh",
      "group": {
        "kind": "test",
        "isDefault": true
      },
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "Start Development Server",
      "type": "shell",
      "command": "./scripts/dev-server.sh",
      "isBackground": true,
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "Performance Benchmark",
      "type": "shell",
      "command": "./enterprise/performance/performance_benchmark.sh",
      "group": "test",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    },
    {
      "label": "Security Scan",
      "type": "shell",
      "command": "./enterprise/security_hardening.sh scan",
      "group": "test",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      }
    }
  ]
}
EOF

cat > .vscode/launch.json << 'EOF'
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug tmux-forceline",
      "type": "bashdb",
      "request": "launch",
      "program": "${workspaceFolder}/forceline.tmux",
      "args": ["status"],
      "env": {
        "FORCELINE_DEV": "true",
        "FORCELINE_DEBUG": "true"
      },
      "console": "integratedTerminal"
    }
  ]
}
EOF

# Install tmux-forceline in development mode
echo "🔧 Installing tmux-forceline in development mode..."
if [[ -f "forceline.tmux" ]]; then
    # Create symlink for easy access
    sudo ln -sf "/workspace/tmux-forceline-cli.sh" "/usr/local/bin/tmux-forceline"
    
    # Initialize with development profile
    if [[ -f "enterprise/config_manager.sh" ]]; then
        ./enterprise/config_manager.sh init development
    fi
fi

# Create development README
cat > DEV_README.md << 'EOF'
# tmux-forceline Development Environment

Welcome to the tmux-forceline development container! This environment is pre-configured with all the tools and dependencies needed for developing, testing, and building tmux-forceline.

## Quick Start

1. **Start Development Environment**:
   ```bash
   start_dev_env
   ```

2. **Run Tests**:
   ```bash
   ./scripts/dev-test.sh
   ```

3. **Build Project**:
   ```bash
   ./scripts/dev-build.sh
   ```

4. **Start Development Server**:
   ```bash
   ./scripts/dev-server.sh
   ```

## Available Commands

- `fl` - Navigate to forceline directory
- `flt` - Run tests
- `flb` - Build project
- `fld` - Show performance dashboard
- `performance-test` - Run performance benchmarks
- `security-scan` - Run security scans
- `monitoring-start` - Start monitoring services

## Development Workflow

1. Make changes to the code
2. Run tests: `./scripts/dev-test.sh`
3. Build and validate: `./scripts/dev-build.sh`
4. Test performance: `performance-test`
5. Commit changes (pre-commit hooks will run automatically)

## VS Code Integration

This dev container includes VS Code integration with:
- Shell script linting and formatting
- Testing framework integration
- Debugging capabilities
- Task automation

## Enterprise Features

All enterprise features are available in development mode:
- Configuration Management
- Security Hardening
- Monitoring & Observability
- Deployment Automation

Run `tmux-forceline --help` to see all available commands.
EOF

echo "✅ tmux-forceline development environment setup completed!"
echo ""
echo "🚀 Ready for development! Key features:"
echo "   📝 All dependencies installed and configured"
echo "   🧪 Testing framework (bats) ready"
echo "   🔍 Code quality tools (shellcheck, markdownlint) configured"
echo "   🏢 Enterprise features initialized"
echo "   ⚙️  VS Code integration configured"
echo "   🔗 Git hooks installed"
echo ""
echo "📚 See DEV_README.md for development workflow and commands"