#!/bin/bash

# Woody Monitoring Setup Script
# This script helps set up and configure the monitoring stack

set -e

echo "🚀 Setting up Woody Monitoring Stack..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Check if we're on woody
if [[ $(hostname) != "woody" ]]; then
    print_warning "This script is designed for the woody server"
    print_warning "Current hostname: $(hostname)"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_status "Checking prerequisites..."

# Check if NixOS is being used
if [[ ! -f /etc/nixos/configuration.nix ]]; then
    print_error "This script is designed for NixOS"
    exit 1
fi

# Check if required directories exist
REQUIRED_DIRS=(
    "alloy"
    "grafana/dashboards/default"
    "grafana/provisioning/alerting/rules"
    "grafana/provisioning/dashboards"
    "grafana/provisioning/datasources"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        print_error "Required directory not found: $dir"
        exit 1
    fi
done

print_success "Prerequisites check passed"

# Validate Alloy configuration
print_status "Validating Alloy configuration..."
if [[ -f "alloy/config.alloy" ]]; then
    if command -v alloy &> /dev/null; then
        if alloy check-config alloy/config.alloy; then
            print_success "Alloy configuration is valid"
        else
            print_error "Alloy configuration validation failed"
            exit 1
        fi
    else
        print_warning "Alloy binary not found, skipping configuration validation"
    fi
else
    print_error "Alloy configuration file not found: alloy/config.alloy"
    exit 1
fi

# Check dashboard files
print_status "Checking dashboard files..."
DASHBOARD_FILES=(
    "grafana/dashboards/default/enhanced-alloy-overview.json"
    "grafana/dashboards/default/security-monitoring.json"
    "grafana/dashboards/default/network-monitoring.json"
    "grafana/dashboards/default/enhanced-container-monitoring.json"
    "grafana/dashboards/default/log-exploration.json"
    "grafana/dashboards/default/multi-host-logs.json"
    "grafana/dashboards/default/overview-dashboard.json"
    "grafana/dashboards/default/enhanced-node-exporter.json"
    "grafana/dashboards/default/process-monitoring.json"
    "grafana/dashboards/default/systemd-services.json"
)

for file in "${DASHBOARD_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        print_success "Found dashboard: $(basename "$file")"
    else
        print_warning "Dashboard file not found: $file"
    fi
done

# Check alerting rules
print_status "Checking alerting rules..."
ALERTING_FILES=(
    "grafana/provisioning/alerting/rules/alloy-health.yml"
    "grafana/provisioning/alerting/rules/system-metrics.yml"
    "grafana/provisioning/alerting/rules/container-metrics.yml"
    "grafana/provisioning/alerting/rules/network-monitoring.yml"
    "grafana/provisioning/alerting/rules/log-monitoring.yml"
    "grafana/provisioning/alerting/prometheus.yml"
)

for file in "${ALERTING_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        print_success "Found alerting rule: $(basename "$file")"
    else
        print_warning "Alerting rule file not found: $file"
    fi
done

# Check configuration files
print_status "Checking configuration files..."
CONFIG_FILES=(
    "grafana.nix"
    "alertmanager.nix"
    "alloy/snmp.yml"
    "alloy/blackbox.yml"
)

for file in "${CONFIG_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        print_success "Found configuration: $file"
    else
        print_warning "Configuration file not found: $file"
    fi
done

# Check network connectivity
print_status "Checking network connectivity..."

# Check if we can reach common monitoring ports
PORTS_TO_CHECK=(
    "localhost:9090"  # Prometheus
    "localhost:3001"  # Grafana
    "localhost:9093"  # Alertmanager
    "localhost:12345" # Alloy
)

for port in "${PORTS_TO_CHECK[@]}"; do
    if timeout 5 bash -c "</dev/tcp/${port%:*}/${port#*:}" 2>/dev/null; then
        print_success "Port ${port#*:} is accessible"
    else
        print_warning "Port ${port#*:} is not accessible (service may not be running)"
    fi
done

# Check SNMP devices
print_status "Checking SNMP device connectivity..."
SNMP_DEVICES=(
    "10.10.100.1"  # Ubiquiti Gateway
)

for device in "${SNMP_DEVICES[@]}"; do
    if ping -c 1 -W 2 "$device" &>/dev/null; then
        print_success "SNMP device $device is reachable"
    else
        print_warning "SNMP device $device is not reachable"
    fi
done

# Check Blackbox targets
print_status "Checking Blackbox probe targets..."
BLACKBOX_TARGETS=(
    "http://10.10.100.1"
    "http://woody:9090"
    "http://woody:3001"
)

for target in "${BLACKBOX_TARGETS[@]}"; do
    if curl -s --max-time 5 "$target" &>/dev/null; then
        print_success "Blackbox target $target is accessible"
    else
        print_warning "Blackbox target $target is not accessible"
    fi
done

# Provide deployment instructions
echo
print_status "Setup validation complete!"
echo
print_status "To deploy the monitoring stack:"
echo "1. Add the monitoring configuration to your NixOS configuration"
echo "2. Rebuild the system: sudo nixos-rebuild switch"
echo "3. Check service status:"
echo "   - sudo systemctl status alloy"
echo "   - sudo systemctl status grafana"
echo "   - sudo systemctl status prometheus"
echo "   - sudo systemctl status alertmanager"
echo
print_status "Access URLs after deployment:"
echo "  - Grafana: http://woody:3001 (admin/admin)"
echo "  - Prometheus: http://woody:9090"
echo "  - Alertmanager: http://woody:9093"
echo "  - Alloy: http://woody:12345"
echo
print_warning "Remember to:"
echo "  - Change default Grafana password"
echo "  - Configure proper SNMP community strings"
echo "  - Set up email notifications in Alertmanager"
echo "  - Review and adjust alert thresholds"
echo "  - Configure log retention policies"
echo
print_success "Monitoring stack setup script completed!"
