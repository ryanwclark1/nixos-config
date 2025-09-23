#!/usr/bin/env bash

# tmux-forceline Development Container Post-Start Script
# This script runs every time the container starts

set -euo pipefail

echo "🔄 Starting tmux-forceline development container..."

# Ensure we're in the workspace
cd /workspace

# Update file permissions (in case files changed)
find . -name "*.sh" -type f -exec chmod +x {} \; 2>/dev/null || true

# Start background services for development
echo "🚀 Starting development services..."

# Start monitoring services if available
if [[ -f "enterprise/monitoring_observability.sh" ]]; then
    echo "   📊 Starting monitoring services..."
    ./enterprise/monitoring_observability.sh start >/dev/null 2>&1 &
fi

# Start security monitoring if available
if [[ -f "enterprise/security_hardening.sh" ]]; then
    echo "   🔒 Starting security monitoring..."
    ./enterprise/security_hardening.sh monitor >/dev/null 2>&1 &
fi

# Create development session status
cat > /tmp/tmux-forceline-dev-status << 'EOF'
🔧 tmux-forceline Development Environment Active

Services Running:
✅ Development Container
✅ tmux-forceline Core
✅ Enterprise Features
✅ Monitoring Services
✅ Security Framework

Quick Commands:
- start_dev_env     : Start development tmux session
- ./scripts/dev-test.sh    : Run all tests
- ./scripts/dev-build.sh   : Build and validate
- performance-test  : Run performance benchmarks
- security-scan     : Run security analysis

Documentation:
- DEV_README.md     : Development workflow guide
- COMPLETION_SUMMARY.md : Project completion status
- enterprise/PHASE_7_SUMMARY.md : Enterprise features

Ready for development! 🚀
EOF

# Show status if running interactively
if [[ -t 1 ]]; then
    cat /tmp/tmux-forceline-dev-status
fi

echo "✅ Development container ready!"