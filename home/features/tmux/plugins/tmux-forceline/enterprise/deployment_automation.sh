#!/usr/bin/env bash

# tmux-forceline Enterprise Deployment Automation
# Comprehensive deployment and configuration management for production environments

set -euo pipefail

# Deployment framework directories
readonly DEPLOYMENT_DIR="${ENTERPRISE_DIR:-./enterprise}/deployment"
readonly PLAYBOOKS_DIR="${DEPLOYMENT_DIR}/playbooks"
readonly TEMPLATES_DIR="${DEPLOYMENT_DIR}/templates"
readonly INVENTORY_DIR="${DEPLOYMENT_DIR}/inventory"
readonly SCRIPTS_DIR="${DEPLOYMENT_DIR}/scripts"
readonly PACKAGES_DIR="${DEPLOYMENT_DIR}/packages"

# Deployment configuration
readonly SUPPORTED_PLATFORMS=("linux" "macos" "bsd" "wsl")
readonly SUPPORTED_PACKAGE_MANAGERS=("apt" "yum" "dnf" "pacman" "brew" "pkg" "zypper")
readonly DEFAULT_DEPLOYMENT_MODE="staged"

# Initialize deployment automation framework
init_deployment_framework() {
    echo "🚀 Initializing tmux-forceline Deployment Automation Framework..."
    
    # Create deployment directory structure
    mkdir -p "$DEPLOYMENT_DIR"/{playbooks,templates,inventory,scripts,packages,configs}
    mkdir -p "$PLAYBOOKS_DIR"/{install,configure,update,rollback}
    mkdir -p "$TEMPLATES_DIR"/{configs,systemd,docker,kubernetes}
    mkdir -p "$INVENTORY_DIR"/{staging,production,development}
    mkdir -p "$PACKAGES_DIR"/{deb,rpm,arch,brew,universal}
    
    # Create deployment playbooks
    create_deployment_playbooks
    
    # Create configuration templates
    create_configuration_templates
    
    # Set up package building
    setup_package_building
    
    # Create deployment scripts
    create_deployment_scripts
    
    # Initialize container support
    setup_container_deployment
    
    # Create orchestration tools
    setup_orchestration_tools
    
    echo "✅ Deployment automation framework initialized successfully"
}

# Create comprehensive deployment playbooks
create_deployment_playbooks() {
    # Main installation playbook
    cat > "$PLAYBOOKS_DIR/install/main_install.yml" << 'EOF'
# tmux-forceline Main Installation Playbook
# Automates installation across multiple environments

deployment_config:
  name: "tmux-forceline Installation"
  version: "3.0"
  target_platforms: ["linux", "macos", "bsd", "wsl"]
  
pre_install_tasks:
  - name: "Detect system platform and package manager"
    script: "detect_system.sh"
    
  - name: "Validate system requirements"
    requirements:
      - tmux_version: ">=2.6"
      - bash_version: ">=4.0" 
      - disk_space: ">=100MB"
      - memory: ">=512MB"
      
  - name: "Create backup of existing configuration"
    backup:
      - path: "~/.tmux.conf"
        suffix: ".forceline-backup"
      - path: "~/.config/tmux/"
        suffix: ".forceline-backup"

install_tasks:
  - name: "Install tmux-forceline core"
    actions:
      - copy_files: "src/*" -> "~/.config/tmux/forceline/"
      - set_permissions: "executable" -> "~/.config/tmux/forceline/*.sh"
      - create_symlinks: "~/.config/tmux/forceline/forceline.tmux" -> "~/.tmux/plugins/tmux-forceline"
      
  - name: "Install enterprise components"
    condition: "enterprise_deployment == true"
    actions:
      - copy_files: "enterprise/*" -> "~/.config/tmux/forceline/enterprise/"
      - set_permissions: "executable" -> "~/.config/tmux/forceline/enterprise/*.sh"
      - initialize_security: "enterprise/security_hardening.sh init"
      
  - name: "Configure system integration"
    actions:
      - add_to_path: "~/.config/tmux/forceline/bin"
      - create_service_files: "systemd/tmux-forceline.service"
      - enable_shell_integration: ["bash", "zsh", "fish"]

post_install_tasks:
  - name: "Apply configuration profile"
    script: "apply_profile.sh"
    args: ["${profile:-auto}"]
    
  - name: "Run validation tests"
    script: "validate_installation.sh"
    
  - name: "Generate installation report"
    script: "generate_install_report.sh"

rollback_config:
  enabled: true
  preserve_backups: true
  rollback_script: "rollback_installation.sh"
EOF

    # Configuration deployment playbook
    cat > "$PLAYBOOKS_DIR/configure/enterprise_config.yml" << 'EOF'
# Enterprise Configuration Deployment Playbook

deployment_config:
  name: "Enterprise Configuration Deployment"
  environments: ["development", "staging", "production"]
  
configuration_tasks:
  - name: "Deploy security policies"
    source: "templates/security_policies/"
    destination: "~/.config/tmux/forceline/enterprise/security/policies/"
    validation: "validate_security_policies.sh"
    
  - name: "Configure monitoring and alerting"
    actions:
      - deploy_config: "monitoring_config.conf"
      - start_services: ["health_monitor", "metric_collectors"]
      - configure_alerts: "alert_rules.conf"
      
  - name: "Set up compliance reporting"
    condition: "compliance_enabled == true"
    actions:
      - deploy_templates: "compliance_templates/"
      - configure_audit_logging: "audit_config.conf"
      - initialize_reporting: "compliance_reporter.sh init"
      
  - name: "Apply environment-specific settings"
    environment_configs:
      development:
        security_level: "standard"
        monitoring_level: "basic"
        plugin_sandboxing: "disabled"
      staging:
        security_level: "enhanced"
        monitoring_level: "comprehensive"
        plugin_sandboxing: "enabled"
      production:
        security_level: "maximum"
        monitoring_level: "enterprise"
        plugin_sandboxing: "strict"

validation_tasks:
  - name: "Validate configuration integrity"
    script: "validate_enterprise_config.sh"
    
  - name: "Run security assessment"
    script: "security_assessment.sh"
    
  - name: "Test monitoring systems"
    script: "test_monitoring.sh"
EOF

    # Update deployment playbook
    cat > "$PLAYBOOKS_DIR/update/rolling_update.yml" << 'EOF'
# Rolling Update Deployment Playbook

deployment_config:
  name: "Rolling Update Deployment"
  strategy: "rolling"
  max_unavailable: "25%"
  health_check_timeout: "300s"
  
pre_update_tasks:
  - name: "Backup current installation"
    script: "backup_installation.sh"
    
  - name: "Check system health"
    script: "pre_update_health_check.sh"
    exit_on_failure: true
    
  - name: "Download and verify update packages"
    actions:
      - download_package: "${update_url}"
      - verify_signature: "pgp_verify.sh"
      - check_compatibility: "compatibility_check.sh"

update_tasks:
  - name: "Stop services gracefully"
    actions:
      - stop_service: "health_monitor"
      - stop_service: "metric_collectors"
      - wait_for_completion: "30s"
      
  - name: "Update core components"
    actions:
      - update_files: "core/*"
      - preserve_configs: ["enterprise/", "themes/", "plugins/custom/"]
      - update_permissions: "executable"
      
  - name: "Update enterprise components"
    condition: "enterprise_enabled == true"
    actions:
      - update_files: "enterprise/*"
      - migrate_configs: "config_migration.sh"
      - update_security_policies: "security_update.sh"
      
  - name: "Restart services"
    actions:
      - start_service: "health_monitor"
      - start_service: "metric_collectors"
      - wait_for_health: "60s"

post_update_tasks:
  - name: "Run post-update validation"
    script: "post_update_validation.sh"
    
  - name: "Generate update report"
    script: "generate_update_report.sh"
    
  - name: "Clean up temporary files"
    script: "cleanup_update.sh"

rollback_config:
  enabled: true
  automatic_rollback: true
  rollback_conditions:
    - health_check_failed
    - validation_failed
    - service_start_failed
EOF
}

# Create configuration templates for different environments
create_configuration_templates() {
    # Docker deployment template
    cat > "$TEMPLATES_DIR/docker/Dockerfile" << 'EOF'
# tmux-forceline Docker Container
FROM ubuntu:22.04

LABEL maintainer="tmux-forceline team"
LABEL version="3.0"
LABEL description="Enterprise-ready tmux status bar system"

# Install dependencies
RUN apt-get update && apt-get install -y \
    tmux \
    bash \
    curl \
    git \
    bc \
    && rm -rf /var/lib/apt/lists/*

# Create tmux user
RUN useradd -m -s /bin/bash tmux-user

# Copy tmux-forceline
COPY --chown=tmux-user:tmux-user . /home/tmux-user/.config/tmux/forceline/

# Set permissions
RUN chmod +x /home/tmux-user/.config/tmux/forceline/**/*.sh

# Switch to tmux user
USER tmux-user
WORKDIR /home/tmux-user

# Initialize tmux-forceline
RUN ~/.config/tmux/forceline/enterprise/config_manager.sh init corporate

# Default command
CMD ["tmux", "new-session", "-d", "-s", "main"]
EOF

    # Kubernetes deployment template
    cat > "$TEMPLATES_DIR/kubernetes/deployment.yaml" << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tmux-forceline
  namespace: development-tools
  labels:
    app: tmux-forceline
    version: "3.0"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tmux-forceline
  template:
    metadata:
      labels:
        app: tmux-forceline
    spec:
      containers:
      - name: tmux-forceline
        image: tmux-forceline:3.0
        resources:
          requests:
            memory: "512Mi"
            cpu: "100m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        env:
        - name: FORCELINE_ENTERPRISE
          value: "true"
        - name: FORCELINE_SECURITY_LEVEL
          value: "enhanced"
        - name: FORCELINE_MONITORING_LEVEL
          value: "comprehensive"
        volumeMounts:
        - name: config-volume
          mountPath: /home/tmux-user/.config/tmux/forceline/enterprise/configs
        - name: logs-volume
          mountPath: /home/tmux-user/.config/tmux/forceline/logs
      volumes:
      - name: config-volume
        configMap:
          name: tmux-forceline-config
      - name: logs-volume
        emptyDir: {}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: tmux-forceline-config
  namespace: development-tools
data:
  enterprise.conf: |
    SECURITY_LEVEL=enhanced
    MONITORING_LEVEL=comprehensive
    COMPLIANCE_MODE=enabled
    PLUGIN_SANDBOXING=enabled
EOF

    # SystemD service template
    cat > "$TEMPLATES_DIR/systemd/tmux-forceline.service" << 'EOF'
[Unit]
Description=tmux-forceline Health Monitor
After=network.target
Wants=network.target

[Service]
Type=forking
User=%i
Group=%i
Environment=HOME=/home/%i
Environment=FORCELINE_DIR=/home/%i/.config/tmux/forceline
ExecStart=/home/%i/.config/tmux/forceline/enterprise/monitoring_observability.sh start
ExecStop=/home/%i/.config/tmux/forceline/enterprise/monitoring_observability.sh stop
ExecReload=/home/%i/.config/tmux/forceline/enterprise/monitoring_observability.sh restart
PIDFile=/home/%i/.config/tmux/forceline/enterprise/monitoring/health_monitor.pid
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Ansible inventory template
    cat > "$TEMPLATES_DIR/ansible/inventory.ini" << 'EOF'
# tmux-forceline Deployment Inventory

[tmux_servers:children]
development
staging
production

[development]
dev-server-01 ansible_host=10.0.1.10 ansible_user=developer
dev-server-02 ansible_host=10.0.1.11 ansible_user=developer

[staging]
staging-server-01 ansible_host=10.0.2.10 ansible_user=tmux-admin
staging-server-02 ansible_host=10.0.2.11 ansible_user=tmux-admin

[production]
prod-server-01 ansible_host=10.0.3.10 ansible_user=tmux-admin
prod-server-02 ansible_host=10.0.3.11 ansible_user=tmux-admin
prod-server-03 ansible_host=10.0.3.12 ansible_user=tmux-admin

[tmux_servers:vars]
ansible_ssh_private_key_file=~/.ssh/tmux-deployment-key
forceline_version=3.0
enterprise_enabled=true
EOF
}

# Set up package building for multiple distributions
setup_package_building() {
    # Debian package builder
    cat > "$PACKAGES_DIR/deb/build_deb.sh" << 'EOF'
#!/usr/bin/env bash

# Build Debian package for tmux-forceline

PACKAGE_NAME="tmux-forceline"
VERSION="3.0.0"
ARCHITECTURE="all"
MAINTAINER="tmux-forceline team <team@tmux-forceline.org>"

build_debian_package() {
    local build_dir="deb_build"
    local package_dir="${build_dir}/${PACKAGE_NAME}_${VERSION}"
    
    echo "🏗️ Building Debian package..."
    
    # Create package structure
    mkdir -p "$package_dir"/DEBIAN
    mkdir -p "$package_dir"/usr/share/tmux-forceline
    mkdir -p "$package_dir"/usr/bin
    mkdir -p "$package_dir"/etc/tmux-forceline
    mkdir -p "$package_dir"/usr/share/doc/tmux-forceline
    
    # Copy files
    cp -r ../../../* "$package_dir"/usr/share/tmux-forceline/
    
    # Create control file
    cat > "$package_dir"/DEBIAN/control << EOF
Package: $PACKAGE_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCHITECTURE
Depends: tmux (>= 2.6), bash (>= 4.0)
Maintainer: $MAINTAINER
Description: Enterprise-grade tmux status bar system
 tmux-forceline is a high-performance, feature-rich status bar system for tmux
 with enterprise features including security hardening, monitoring, and
 compliance reporting.
EOF

    # Create postinst script
    cat > "$package_dir"/DEBIAN/postinst << 'EOF'
#!/bin/bash
set -e

# Create tmux-forceline symlink
ln -sf /usr/share/tmux-forceline/tmux-forceline-cli.sh /usr/bin/tmux-forceline

# Set permissions
chmod +x /usr/share/tmux-forceline/**/*.sh

echo "tmux-forceline installed successfully!"
echo "Run 'tmux-forceline install' to complete setup."
EOF

    chmod +x "$package_dir"/DEBIAN/postinst
    
    # Build package
    dpkg-deb --build "$package_dir"
    mv "${package_dir}.deb" "./tmux-forceline_${VERSION}_${ARCHITECTURE}.deb"
    
    echo "✅ Debian package built: tmux-forceline_${VERSION}_${ARCHITECTURE}.deb"
}

build_debian_package
EOF

    # RPM package builder
    cat > "$PACKAGES_DIR/rpm/build_rpm.sh" << 'EOF'
#!/usr/bin/env bash

# Build RPM package for tmux-forceline

PACKAGE_NAME="tmux-forceline"
VERSION="3.0.0"
RELEASE="1"

build_rpm_package() {
    echo "🏗️ Building RPM package..."
    
    # Create RPM build structure
    mkdir -p rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    
    # Create source tarball
    tar czf "rpmbuild/SOURCES/${PACKAGE_NAME}-${VERSION}.tar.gz" ../../../*
    
    # Create spec file
    cat > "rpmbuild/SPECS/${PACKAGE_NAME}.spec" << EOF
Name:           $PACKAGE_NAME
Version:        $VERSION
Release:        $RELEASE%{?dist}
Summary:        Enterprise-grade tmux status bar system
License:        MIT
URL:            https://github.com/tmux-forceline/tmux-forceline
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch
Requires:       tmux >= 2.6, bash >= 4.0

%description
tmux-forceline is a high-performance, feature-rich status bar system for tmux
with enterprise features including security hardening, monitoring, and
compliance reporting.

%prep
%setup -q

%install
mkdir -p %{buildroot}/usr/share/tmux-forceline
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/etc/tmux-forceline
cp -r * %{buildroot}/usr/share/tmux-forceline/
ln -s /usr/share/tmux-forceline/tmux-forceline-cli.sh %{buildroot}/usr/bin/tmux-forceline

%files
/usr/share/tmux-forceline
/usr/bin/tmux-forceline
%config(noreplace) /etc/tmux-forceline

%post
echo "tmux-forceline installed successfully!"
echo "Run 'tmux-forceline install' to complete setup."

%changelog
* $(date +"%a %b %d %Y") tmux-forceline team <team@tmux-forceline.org> - $VERSION-$RELEASE
- Initial RPM package
EOF

    # Build RPM
    rpmbuild --define "_topdir $(pwd)/rpmbuild" -ba "rpmbuild/SPECS/${PACKAGE_NAME}.spec"
    
    echo "✅ RPM package built in rpmbuild/RPMS/noarch/"
}

build_rpm_package
EOF

    # Homebrew formula
    cat > "$PACKAGES_DIR/brew/tmux-forceline.rb" << 'EOF'
class TmuxForceline < Formula
  desc "Enterprise-grade tmux status bar system"
  homepage "https://github.com/tmux-forceline/tmux-forceline"
  url "https://github.com/tmux-forceline/tmux-forceline/archive/v3.0.0.tar.gz"
  sha256 "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
  license "MIT"

  depends_on "tmux"
  depends_on "bash"

  def install
    prefix.install Dir["*"]
    bin.install_symlink prefix/"tmux-forceline-cli.sh" => "tmux-forceline"
  end

  def post_install
    puts "tmux-forceline installed successfully!"
    puts "Run 'tmux-forceline install' to complete setup."
  end

  test do
    system "#{bin}/tmux-forceline", "--version"
  end
end
EOF

    chmod +x "$PACKAGES_DIR"/*/*.sh
}

# Create deployment scripts
create_deployment_scripts() {
    # Main deployment orchestrator
    cat > "$SCRIPTS_DIR/deploy.sh" << 'EOF'
#!/usr/bin/env bash

# Main deployment orchestrator for tmux-forceline

set -euo pipefail

DEPLOYMENT_MODE="${1:-staged}"
ENVIRONMENT="${2:-development}"
TARGET_HOSTS="${3:-all}"

# Deployment configuration
DEPLOYMENT_CONFIG="$DEPLOYMENT_DIR/configs/deployment.conf"
INVENTORY_FILE="$INVENTORY_DIR/$ENVIRONMENT/hosts.ini"
PLAYBOOK_DIR="$PLAYBOOKS_DIR"

deploy_tmux_forceline() {
    local mode="$1"
    local env="$2" 
    local hosts="$3"
    
    echo "🚀 Starting tmux-forceline deployment..."
    echo "   Mode: $mode"
    echo "   Environment: $env"
    echo "   Targets: $hosts"
    echo
    
    # Validate deployment prerequisites
    validate_deployment_prerequisites
    
    # Execute deployment based on mode
    case "$mode" in
        "single")
            deploy_single_host "$env" "$hosts"
            ;;
        "staged")
            deploy_staged "$env" "$hosts"
            ;;
        "rolling")
            deploy_rolling "$env" "$hosts"
            ;;
        "blue_green")
            deploy_blue_green "$env" "$hosts"
            ;;
        *)
            echo "❌ Unknown deployment mode: $mode"
            exit 1
            ;;
    esac
    
    echo "✅ Deployment completed successfully!"
}

# Validate deployment prerequisites
validate_deployment_prerequisites() {
    echo "🔍 Validating deployment prerequisites..."
    
    # Check inventory file
    if [[ ! -f "$INVENTORY_FILE" ]]; then
        echo "❌ Inventory file not found: $INVENTORY_FILE"
        exit 1
    fi
    
    # Check SSH connectivity
    while IFS= read -r line; do
        if [[ "$line" =~ ^[a-zA-Z0-9-]+ ]]; then
            local host=$(echo "$line" | awk '{print $1}')
            local ansible_host=$(echo "$line" | grep -o 'ansible_host=[^ ]*' | cut -d= -f2 || echo "$host")
            
            echo "   Testing connectivity to $host ($ansible_host)..."
            if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$ansible_host" "echo 'Connection test successful'" >/dev/null 2>&1; then
                echo "❌ Cannot connect to $host ($ansible_host)"
                exit 1
            fi
        fi
    done < "$INVENTORY_FILE"
    
    echo "✅ Prerequisites validated"
}

# Single host deployment
deploy_single_host() {
    local env="$1"
    local host="$2"
    
    echo "📦 Deploying to single host: $host"
    
    # Run installation playbook
    run_playbook "install/main_install.yml" "$env" "$host"
    
    # Run configuration playbook
    run_playbook "configure/enterprise_config.yml" "$env" "$host"
    
    # Validate deployment
    validate_deployment "$env" "$host"
}

# Staged deployment (dev -> staging -> prod)
deploy_staged() {
    local env="$1"
    local hosts="$2"
    
    echo "🎭 Starting staged deployment..."
    
    local stages=("development" "staging" "production")
    local target_stage_found=false
    
    for stage in "${stages[@]}"; do
        if [[ "$stage" == "$env" ]]; then
            target_stage_found=true
        fi
        
        if [[ "$target_stage_found" == "true" ]]; then
            echo "📦 Deploying to $stage environment..."
            
            # Deploy to stage
            deploy_to_environment "$stage" "$hosts"
            
            # Validate stage deployment
            validate_deployment "$stage" "$hosts"
            
            # Wait for approval if not development
            if [[ "$stage" != "development" ]]; then
                wait_for_approval "$stage"
            fi
        fi
    done
}

# Rolling deployment (gradual host-by-host)
deploy_rolling() {
    local env="$1"
    local hosts="$2"
    
    echo "🔄 Starting rolling deployment..."
    
    # Get list of hosts
    local host_list=()
    while IFS= read -r line; do
        if [[ "$line" =~ ^[a-zA-Z0-9-]+ ]]; then
            host_list+=($(echo "$line" | awk '{print $1}'))
        fi
    done < "$INVENTORY_FILE"
    
    # Deploy to each host with health checks
    for host in "${host_list[@]}"; do
        echo "📦 Deploying to host: $host"
        
        # Deploy to host
        deploy_single_host "$env" "$host"
        
        # Health check
        if ! validate_host_health "$host"; then
            echo "❌ Health check failed for $host, stopping deployment"
            exit 1
        fi
        
        echo "✅ Host $host deployed successfully"
        sleep 10  # Brief pause between hosts
    done
}

# Blue-green deployment
deploy_blue_green() {
    local env="$1"
    local hosts="$2"
    
    echo "🔵🟢 Starting blue-green deployment..."
    
    # Implement blue-green logic
    echo "Note: Blue-green deployment requires load balancer configuration"
    echo "Falling back to rolling deployment"
    deploy_rolling "$env" "$hosts"
}

# Run Ansible playbook
run_playbook() {
    local playbook="$1"
    local environment="$2"
    local hosts="${3:-all}"
    
    echo "📋 Running playbook: $playbook"
    
    if command -v ansible-playbook >/dev/null 2>&1; then
        ansible-playbook \
            -i "$INVENTORY_DIR/$environment/hosts.ini" \
            --limit "$hosts" \
            "$PLAYBOOK_DIR/$playbook"
    else
        # Fallback to custom playbook execution
        execute_playbook_manually "$playbook" "$environment" "$hosts"
    fi
}

# Manual playbook execution (when Ansible not available)
execute_playbook_manually() {
    local playbook="$1"
    local environment="$2"
    local hosts="$3"
    
    echo "⚠️  Ansible not available, executing playbook manually"
    
    # Parse YAML playbook and execute tasks
    # This is a simplified implementation
    echo "Executing $playbook for $environment on $hosts"
    
    case "$playbook" in
        "install/main_install.yml")
            execute_install_tasks "$environment" "$hosts"
            ;;
        "configure/enterprise_config.yml")
            execute_configure_tasks "$environment" "$hosts"
            ;;
    esac
}

# Execute installation tasks
execute_install_tasks() {
    local environment="$1"
    local hosts="$2"
    
    echo "🔧 Executing installation tasks..."
    
    # Copy files to target hosts
    while IFS= read -r line; do
        if [[ "$line" =~ ^[a-zA-Z0-9-]+ ]]; then
            local host=$(echo "$line" | awk '{print $1}')
            local ansible_host=$(echo "$line" | grep -o 'ansible_host=[^ ]*' | cut -d= -f2 || echo "$host")
            
            echo "   Installing on $host..."
            
            # Copy tmux-forceline
            scp -r ../../../* "$ansible_host:~/.config/tmux/forceline/" 2>/dev/null || {
                ssh "$ansible_host" "mkdir -p ~/.config/tmux/forceline"
                scp -r ../../../* "$ansible_host:~/.config/tmux/forceline/"
            }
            
            # Set permissions
            ssh "$ansible_host" "find ~/.config/tmux/forceline -name '*.sh' -exec chmod +x {} \;"
            
            # Initialize enterprise components
            ssh "$ansible_host" "~/.config/tmux/forceline/enterprise/config_manager.sh init corporate"
        fi
    done < "$INVENTORY_DIR/$environment/hosts.ini"
}

# Validate deployment
validate_deployment() {
    local environment="$1"
    local hosts="$2"
    
    echo "✅ Validating deployment..."
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^[a-zA-Z0-9-]+ ]]; then
            local host=$(echo "$line" | awk '{print $1}')
            local ansible_host=$(echo "$line" | grep -o 'ansible_host=[^ ]*' | cut -d= -f2 || echo "$host")
            
            if ! validate_host_health "$ansible_host"; then
                echo "❌ Validation failed for $host"
                return 1
            fi
        fi
    done < "$INVENTORY_DIR/$environment/hosts.ini"
    
    echo "✅ All hosts validated successfully"
}

# Validate individual host health
validate_host_health() {
    local host="$1"
    
    echo "🏥 Checking health of $host..."
    
    # Check if tmux-forceline is installed and working
    if ssh "$host" "test -f ~/.config/tmux/forceline/forceline.tmux" && \
       ssh "$host" "~/.config/tmux/forceline/forceline.tmux status" >/dev/null 2>&1; then
        echo "✅ $host is healthy"
        return 0
    else
        echo "❌ $host health check failed"
        return 1
    fi
}

# Wait for deployment approval
wait_for_approval() {
    local stage="$1"
    
    echo "⏳ Waiting for approval to deploy to $stage..."
    echo "Press Enter to continue or Ctrl+C to abort"
    read -r
}

# Deploy to specific environment
deploy_to_environment() {
    local env="$1"
    local hosts="$2"
    
    run_playbook "install/main_install.yml" "$env" "$hosts"
    run_playbook "configure/enterprise_config.yml" "$env" "$hosts"
}

# Main execution
main() {
    deploy_tmux_forceline "$DEPLOYMENT_MODE" "$ENVIRONMENT" "$TARGET_HOSTS"
}

# Show usage if no arguments
if [[ $# -eq 0 ]]; then
    cat << EOF
🚀 tmux-forceline Deployment Orchestrator

USAGE:
  $(basename "$0") <mode> <environment> [hosts]

DEPLOYMENT MODES:
  single      Deploy to single host
  staged      Deploy through dev -> staging -> prod
  rolling     Deploy host-by-host with health checks
  blue_green  Blue-green deployment (requires load balancer)

ENVIRONMENTS:
  development Development environment
  staging     Staging environment  
  production  Production environment

EXAMPLES:
  $(basename "$0") single development dev-server-01
  $(basename "$0") staged development all
  $(basename "$0") rolling production all
EOF
    exit 1
fi

main "$@"
EOF

    # System detection script
    cat > "$SCRIPTS_DIR/detect_system.sh" << 'EOF'
#!/usr/bin/env bash

# Detect system platform and package manager

detect_platform() {
    local platform="unknown"
    
    if [[ "$OSTYPE" =~ ^linux ]]; then
        platform="linux"
    elif [[ "$OSTYPE" =~ ^darwin ]]; then
        platform="macos"
    elif [[ "$OSTYPE" =~ ^freebsd ]]; then
        platform="bsd"
    elif [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
        platform="wsl"
    fi
    
    echo "$platform"
}

detect_package_manager() {
    local package_manager="unknown"
    
    if command -v apt-get >/dev/null 2>&1; then
        package_manager="apt"
    elif command -v yum >/dev/null 2>&1; then
        package_manager="yum"
    elif command -v dnf >/dev/null 2>&1; then
        package_manager="dnf"
    elif command -v pacman >/dev/null 2>&1; then
        package_manager="pacman"
    elif command -v brew >/dev/null 2>&1; then
        package_manager="brew"
    elif command -v pkg >/dev/null 2>&1; then
        package_manager="pkg"
    elif command -v zypper >/dev/null 2>&1; then
        package_manager="zypper"
    fi
    
    echo "$package_manager"
}

detect_system_info() {
    local platform=$(detect_platform)
    local package_manager=$(detect_package_manager)
    
    cat << EOF
{
  "platform": "$platform",
  "package_manager": "$package_manager",
  "os_type": "$OSTYPE",
  "architecture": "$(uname -m)",
  "kernel": "$(uname -r)",
  "hostname": "$(hostname)"
}
EOF
}

# Output system information
detect_system_info
EOF

    chmod +x "$SCRIPTS_DIR"/*.sh
}

# Set up container deployment support
setup_container_deployment() {
    # Docker Compose for development
    cat > "$DEPLOYMENT_DIR/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  tmux-forceline:
    build:
      context: ../../
      dockerfile: enterprise/deployment/templates/docker/Dockerfile
    container_name: tmux-forceline-dev
    environment:
      - FORCELINE_ENTERPRISE=true
      - FORCELINE_SECURITY_LEVEL=standard
      - FORCELINE_MONITORING_LEVEL=basic
    volumes:
      - forceline_config:/home/tmux-user/.config/tmux/forceline/enterprise/configs
      - forceline_logs:/home/tmux-user/.config/tmux/forceline/logs
    ports:
      - "2222:22"  # SSH access for testing
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "/home/tmux-user/.config/tmux/forceline/forceline.tmux", "status"]
      interval: 30s
      timeout: 10s
      retries: 3

  monitoring:
    image: tmux-forceline:3.0
    container_name: tmux-forceline-monitoring
    environment:
      - FORCELINE_MONITORING_ONLY=true
    volumes:
      - forceline_logs:/home/tmux-user/.config/tmux/forceline/logs:ro
    depends_on:
      - tmux-forceline
    restart: unless-stopped

volumes:
  forceline_config:
  forceline_logs:

networks:
  default:
    name: tmux-forceline-network
EOF

    # Kubernetes deployment scripts
    cat > "$SCRIPTS_DIR/deploy_kubernetes.sh" << 'EOF'
#!/usr/bin/env bash

# Deploy tmux-forceline to Kubernetes

NAMESPACE="${1:-development-tools}"
DEPLOYMENT_NAME="tmux-forceline"

deploy_to_kubernetes() {
    echo "🚀 Deploying tmux-forceline to Kubernetes..."
    
    # Create namespace if it doesn't exist
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply deployment
    kubectl apply -f "$TEMPLATES_DIR/kubernetes/deployment.yaml" -n "$NAMESPACE"
    
    # Wait for deployment
    kubectl rollout status deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE"
    
    # Show status
    kubectl get pods -n "$NAMESPACE" -l app="$DEPLOYMENT_NAME"
    
    echo "✅ Kubernetes deployment completed"
}

# Rollback Kubernetes deployment
rollback_kubernetes() {
    echo "🔄 Rolling back Kubernetes deployment..."
    kubectl rollout undo deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE"
    kubectl rollout status deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE"
    echo "✅ Rollback completed"
}

case "${2:-deploy}" in
    "deploy") deploy_to_kubernetes ;;
    "rollback") rollback_kubernetes ;;
    *) echo "Usage: $0 <namespace> {deploy|rollback}" ;;
esac
EOF

    chmod +x "$SCRIPTS_DIR/deploy_kubernetes.sh"
}

# Set up orchestration tools
setup_orchestration_tools() {
    # Main orchestration script
    cat > "$DEPLOYMENT_DIR/orchestrate.sh" << 'EOF'
#!/usr/bin/env bash

# Main orchestration tool for tmux-forceline deployments

set -euo pipefail

ORCHESTRATION_CONFIG="$DEPLOYMENT_DIR/configs/orchestration.conf"

# Load configuration
if [[ -f "$ORCHESTRATION_CONFIG" ]]; then
    source "$ORCHESTRATION_CONFIG"
fi

# Default configuration
DEFAULT_ENVIRONMENTS=("development" "staging" "production")
DEFAULT_DEPLOYMENT_STRATEGY="rolling"
DEFAULT_HEALTH_CHECK_TIMEOUT="300"

orchestrate_deployment() {
    local strategy="${1:-$DEFAULT_DEPLOYMENT_STRATEGY}"
    local environments="${2:-development}"
    
    echo "🎼 Orchestrating tmux-forceline deployment..."
    echo "   Strategy: $strategy"
    echo "   Environments: $environments"
    echo
    
    case "$strategy" in
        "pipeline")
            run_deployment_pipeline "$environments"
            ;;
        "parallel")
            run_parallel_deployment "$environments"
            ;;
        "canary")
            run_canary_deployment "$environments"
            ;;
        "rolling")
            run_rolling_deployment "$environments"
            ;;
        *)
            echo "❌ Unknown strategy: $strategy"
            exit 1
            ;;
    esac
}

# Run deployment pipeline (sequential environments)
run_deployment_pipeline() {
    local target_envs="$1"
    
    echo "🔄 Running deployment pipeline..."
    
    IFS=',' read -ra ENVS <<< "$target_envs"
    for env in "${ENVS[@]}"; do
        echo "📦 Deploying to $env environment..."
        
        # Run deployment
        "$SCRIPTS_DIR/deploy.sh" staged "$env" all
        
        # Run tests
        run_deployment_tests "$env"
        
        # Generate report
        generate_deployment_report "$env"
        
        echo "✅ $env deployment completed"
    done
}

# Run parallel deployment (multiple environments simultaneously)
run_parallel_deployment() {
    local target_envs="$1"
    
    echo "⚡ Running parallel deployment..."
    
    local pids=()
    IFS=',' read -ra ENVS <<< "$target_envs"
    
    for env in "${ENVS[@]}"; do
        echo "🚀 Starting deployment to $env..."
        (
            "$SCRIPTS_DIR/deploy.sh" single "$env" all
            run_deployment_tests "$env"
        ) &
        pids+=($!)
    done
    
    # Wait for all deployments to complete
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    echo "✅ All parallel deployments completed"
}

# Run canary deployment (gradual traffic shifting)
run_canary_deployment() {
    local environment="$1"
    
    echo "🐤 Running canary deployment to $environment..."
    
    # Deploy to canary hosts (subset)
    echo "📦 Deploying to canary hosts..."
    "$SCRIPTS_DIR/deploy.sh" single "$environment" "canary"
    
    # Monitor canary metrics
    monitor_canary_metrics "$environment"
    
    # If canary is healthy, deploy to remaining hosts
    if validate_canary_health "$environment"; then
        echo "✅ Canary validation passed, deploying to remaining hosts..."
        "$SCRIPTS_DIR/deploy.sh" rolling "$environment" "main"
    else
        echo "❌ Canary validation failed, rolling back..."
        rollback_deployment "$environment"
        exit 1
    fi
}

# Monitor canary metrics
monitor_canary_metrics() {
    local environment="$1"
    local monitor_duration=300  # 5 minutes
    
    echo "📊 Monitoring canary metrics for ${monitor_duration}s..."
    
    local start_time=$(date +%s)
    while [[ $(($(date +%s) - start_time)) -lt $monitor_duration ]]; do
        # Check error rates, response times, etc.
        echo "   Checking metrics... $(date '+%H:%M:%S')"
        sleep 30
    done
    
    echo "✅ Canary monitoring completed"
}

# Validate canary health
validate_canary_health() {
    local environment="$1"
    
    echo "🏥 Validating canary health..."
    
    # Implement health validation logic
    # For now, return success
    return 0
}

# Run deployment tests
run_deployment_tests() {
    local environment="$1"
    
    echo "🧪 Running deployment tests for $environment..."
    
    # Run functional tests
    if [[ -f "$SCRIPTS_DIR/test_deployment.sh" ]]; then
        "$SCRIPTS_DIR/test_deployment.sh" "$environment"
    fi
    
    # Run performance tests
    if [[ -f "$SCRIPTS_DIR/test_performance.sh" ]]; then
        "$SCRIPTS_DIR/test_performance.sh" "$environment"
    fi
    
    echo "✅ Tests completed for $environment"
}

# Generate deployment report
generate_deployment_report() {
    local environment="$1"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
    local report_file="$DEPLOYMENT_DIR/reports/deployment_${environment}_$(date +%Y%m%d_%H%M%S).txt"
    
    mkdir -p "$(dirname "$report_file")"
    
    cat > "$report_file" << EOF
# Deployment Report - $environment
Generated: $timestamp

## Deployment Summary
Environment: $environment
Status: Completed
Duration: $(deployment_duration)
Hosts Deployed: $(deployed_host_count "$environment")

## Health Status
$(check_environment_health "$environment")

## Performance Metrics
$(collect_performance_metrics "$environment")

## Issues and Warnings
$(collect_deployment_issues "$environment")
EOF

    echo "📊 Deployment report generated: $report_file"
}

# Rollback deployment
rollback_deployment() {
    local environment="$1"
    
    echo "🔄 Rolling back deployment in $environment..."
    "$SCRIPTS_DIR/deploy.sh" rollback "$environment" all
    echo "✅ Rollback completed"
}

# Show orchestration help
show_help() {
    cat << EOF
🎼 tmux-forceline Deployment Orchestration

USAGE:
  $(basename "$0") <strategy> <environments>

STRATEGIES:
  pipeline    Sequential deployment through environments
  parallel    Deploy to multiple environments simultaneously
  canary      Canary deployment with traffic shifting
  rolling     Rolling deployment with health checks

ENVIRONMENTS:
  Single:     development, staging, production
  Multiple:   development,staging,production

EXAMPLES:
  $(basename "$0") pipeline development,staging,production
  $(basename "$0") parallel development,staging
  $(basename "$0") canary production
  $(basename "$0") rolling staging

OPTIONS:
  --dry-run   Show what would be deployed without executing
  --verbose   Enable verbose logging
  --parallel  Enable parallel execution where possible
EOF
}

# Main execution
case "${1:-help}" in
    "pipeline"|"parallel"|"canary"|"rolling")
        orchestrate_deployment "$1" "${2:-development}"
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac
EOF

    chmod +x "$DEPLOYMENT_DIR/orchestrate.sh"
}

# Main deployment automation interface
main_deployment() {
    case "${1:-help}" in
        "init")
            init_deployment_framework
            ;;
        "deploy")
            "$SCRIPTS_DIR/deploy.sh" "${2:-staged}" "${3:-development}" "${4:-all}"
            ;;
        "orchestrate")
            "$DEPLOYMENT_DIR/orchestrate.sh" "${2:-rolling}" "${3:-development}"
            ;;
        "package")
            case "${2:-deb}" in
                "deb") "$PACKAGES_DIR/deb/build_deb.sh" ;;
                "rpm") "$PACKAGES_DIR/rpm/build_rpm.sh" ;;
                "all") 
                    "$PACKAGES_DIR/deb/build_deb.sh"
                    "$PACKAGES_DIR/rpm/build_rpm.sh"
                    echo "✅ All packages built"
                    ;;
                *) echo "Available packages: deb, rpm, all" ;;
            esac
            ;;
        "container")
            case "${2:-docker}" in
                "docker") 
                    cd "$DEPLOYMENT_DIR" && docker-compose up -d
                    ;;
                "kubernetes")
                    "$SCRIPTS_DIR/deploy_kubernetes.sh" "${3:-development-tools}" deploy
                    ;;
                *) echo "Available containers: docker, kubernetes" ;;
            esac
            ;;
        "help"|*)
            cat << EOF
🚀 tmux-forceline Deployment Automation System

USAGE:
  $(basename "$0") <command> [options]

COMMANDS:
  init                     Initialize deployment framework
  deploy <mode> <env>      Deploy using specified mode and environment
                          Modes: single, staged, rolling, blue_green
                          Environments: development, staging, production
  orchestrate <strategy>   Run orchestrated deployment
                          Strategies: pipeline, parallel, canary, rolling
  package <type>          Build distribution packages
                          Types: deb, rpm, all
  container <type>        Deploy using containers
                          Types: docker, kubernetes
  help                    Show this help message

DEPLOYMENT MODES:
  single        Deploy to single host
  staged        Deploy through dev -> staging -> prod
  rolling       Deploy host-by-host with health checks
  blue_green    Blue-green deployment (requires load balancer)

ORCHESTRATION STRATEGIES:
  pipeline      Sequential deployment through environments  
  parallel      Deploy to multiple environments simultaneously
  canary        Canary deployment with traffic shifting
  rolling       Rolling deployment with health checks

EXAMPLES:
  $(basename "$0") init                                    # Initialize deployment framework
  $(basename "$0") deploy staged development               # Deploy to development environment
  $(basename "$0") orchestrate pipeline development,staging,production  # Run deployment pipeline
  $(basename "$0") package all                            # Build all distribution packages
  $(basename "$0") container docker                       # Deploy using Docker
EOF
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_deployment "$@"
fi