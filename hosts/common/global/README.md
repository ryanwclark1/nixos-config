# Global NixOS Modules

This directory contains global NixOS modules that are applied to all hosts in the infrastructure.

## Directory Structure

```
hosts/common/global/
├── default.nix              # Main entry point - imports all modules
├── core/                    # Essential system modules
│   ├── default.nix
│   ├── boot.nix            # Boot configuration
│   ├── system.nix          # Basic system services and hardware
│   ├── locale.nix          # Internationalization settings
│   ├── logging.nix         # System logging configuration
│   └── environment.nix     # Environment variables and aliases
├── networking/             # Network-related modules
│   ├── default.nix
│   └── networking.nix      # Network configuration, firewall, DNS
├── security/               # Security modules
│   ├── default.nix
│   ├── security.nix        # Security hardening
│   ├── fail2ban.nix        # Intrusion prevention
│   └── openssh.nix         # SSH configuration
├── nix/                    # Nix-specific modules
│   ├── default.nix
│   ├── nix.nix            # Nix package manager settings
│   ├── nh.nix             # Nix helper
│   └── nix-ld.nix         # Nix loader
├── performance/            # Performance tuning
│   ├── default.nix
│   ├── performance.nix     # System performance tuning
│   └── systemd-initrd.nix  # Initrd configuration
├── virtualisation/         # Container and VM support
│   ├── default.nix
│   └── podman.nix         # Podman container runtime
├── monitoring/             # System monitoring
│   ├── default.nix
│   └── prometheus.nix     # Prometheus exporters and monitoring tools
├── validation/             # Configuration validation
│   ├── default.nix
│   └── assertions.nix     # Configuration assertions and warnings
├── sops.nix               # Secrets management
└── README.md              # This file
```

## Module Groups

### Core (`./core/`)
Essential system modules that every host needs:
- **boot.nix**: Bootloader configuration
- **system.nix**: Basic system services, hardware enablement
- **locale.nix**: Internationalization and timezone settings
- **logging.nix**: Systemd journal and syslog configuration
- **environment.nix**: Environment variables, shell aliases, and session variables

### Networking (`./networking/`)
Network configuration and connectivity:
- **networking.nix**: NetworkManager, firewall, DNS configuration

### Security (`./security/`)
Security hardening and access control:
- **security.nix**: Audit system, PAM limits, security policies
- **fail2ban.nix**: Intrusion detection and prevention
- **openssh.nix**: SSH server configuration

### Nix (`./nix/`)
Nix ecosystem configuration:
- **nix.nix**: Nix package manager settings
- **nh.nix**: Nix helper configuration
- **nix-ld.nix**: Nix loader for non-Nix binaries

### Performance (`./performance/`)
System performance optimization:
- **performance.nix**: Kernel tuning, performance services
- **systemd-initrd.nix**: Initrd configuration

### Virtualisation (`./virtualisation/`)
Container and virtual machine support:
- **podman.nix**: Podman container runtime configuration

### Monitoring (`./monitoring/`)
System monitoring and observability:
- **prometheus.nix**: Prometheus exporters (node, process, blackbox) and monitoring tools

### Validation (`./validation/`)
Configuration validation and quality assurance:
- **assertions.nix**: Configuration assertions, warnings, and best practice checks

### Secrets Management
- **sops.nix**: SOPS secrets management configuration and package

## Environment Variables

The global configuration automatically includes environment-specific variables:
- `ACCENT_EMAIL`: Read from `env/accent-email-address`
- `PERSONAL_DOMAIN`: Set to "techcasa.io"
- Standard development and system environment variables

## Adding New Modules

1. **Determine the appropriate group** for your module
2. **Create the module file** in the relevant subdirectory
3. **Add the import** to the subdirectory's `default.nix`
4. **Update this README** if adding a new group
5. **Add validation** in `validation/assertions.nix` if needed

## Host-Specific Overrides

To override global settings for specific hosts, use `lib.mkForce` or `lib.mkOverride`:

```nix
# In host-specific configuration
{
  boot.loader.grub.enable = lib.mkForce false;
  boot.loader.systemd-boot.enable = true;

  # Override timezone
  time.timeZone = "America/New_York";

  # Disable monitoring on specific hosts
  services.prometheus.exporters.node.enable = false;
}
```

## Configuration Validation

The validation module automatically checks for:
- **Security**: Firewall, audit system, SSH enabled
- **System**: Time sync, locale settings
- **Network**: NetworkManager, DNS resolution
- **Nix**: Experimental features, garbage collection

## Dependencies

- All modules depend on the main `default.nix` for basic configuration
- Security modules may depend on networking configuration
- Performance modules may depend on core system services
- Monitoring modules depend on core system services
- Validation modules depend on all other modules

## Best Practices

1. **Keep modules focused** on single responsibilities
2. **Use descriptive names** for modules
3. **Document any non-obvious** configurations
4. **Test changes** on a single host before applying globally
5. **Use conditional imports** for optional features
6. **Add validation** for critical configuration requirements
7. **Use `lib.mkDefault`** for values that should be overridable
8. **Use `lib.mkForce`** for values that should override host settings

## Monitoring

The monitoring module provides:
- **Prometheus Node Exporter**: System metrics (CPU, memory, disk, network)
- **Process Exporter**: Process-level metrics (optional)
- **Blackbox Exporter**: Network monitoring (optional)
- **System monitoring tools**: htop, iotop, smartmontools, etc.

## Troubleshooting

### Common Issues

1. **Validation failures**: Check the assertions in `validation/assertions.nix`
2. **Environment variables**: Verify `env/accent-email-address` exists
3. **Monitoring**: Ensure Prometheus exporters are enabled if needed
4. **Performance**: Check that performance modules are properly configured

### Debugging

```bash
# Check configuration validation
nixos-rebuild dry-activate

# Test specific module
nix eval .#nixosConfigurations.<host>.config.<module>

# View generated configuration
nix show-config
```
