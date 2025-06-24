# Global Modules Quick Reference

## Common Operations

### Adding a New Module

1. **Create the module file** in the appropriate subdirectory:
   ```bash
   # Example: Adding a new security module
   touch hosts/common/global/security/new-security-feature.nix
   ```

2. **Add the import** to the subdirectory's `default.nix`:
   ```nix
   # In hosts/common/global/security/default.nix
   {
     imports = [
       ./security.nix
       ./fail2ban.nix
       ./openssh.nix
       ./new-security-feature.nix  # Add this line
     ];
   }
   ```

3. **Update documentation** in `README.md`

### Overriding Global Settings

```nix
# In host-specific configuration
{
  # Override with higher priority
  boot.loader.grub.enable = lib.mkForce false;

  # Override with default priority
  time.timeZone = "America/New_York";

  # Disable optional features
  services.prometheus.exporters.node.enable = false;
}
```

### Environment Variables

The global configuration automatically includes:
- `ACCENT_EMAIL`: From `env/accent-email-address`
- `COMPANY_DOMAIN`: "techcasa.io"
- Standard development variables

### Monitoring

**Enable/Disable Prometheus exporters:**
```nix
{
  services.prometheus.exporters = {
    node.enable = true;      # System metrics
    process.enable = false;  # Process metrics
    blackbox.enable = false; # Network monitoring
  };
}
```

**Access metrics:**
- Node exporter: `http://localhost:9100/metrics`
- Process exporter: `http://localhost:9256/metrics`
- Blackbox exporter: `http://localhost:9115/metrics`

## Troubleshooting

### Configuration Validation

**Check for validation errors:**
```bash
nixos-rebuild dry-activate
```

**Common validation failures:**
- Firewall not enabled
- Audit system not enabled
- SSH not enabled
- Time sync not enabled
- Locale not set correctly

### Debugging Modules

**Test specific module:**
```bash
nix eval .#nixosConfigurations.<host>.config.networking
```

**View generated configuration:**
```bash
nix show-config
```

**Check module imports:**
```bash
nix eval .#nixosConfigurations.<host>.config._module.args.modules
```

### Performance Issues

**Check performance settings:**
```bash
# Kernel parameters
cat /proc/sys/vm/swappiness
cat /proc/sys/vm/dirty_ratio

# Systemd-oomd status
systemctl status systemd-oomd

# fstrim status
systemctl status fstrim.timer
```

### Monitoring Issues

**Check Prometheus exporters:**
```bash
# Node exporter
systemctl status prometheus-node-exporter

# Check metrics endpoint
curl http://localhost:9100/metrics | head -20
```

**Common monitoring issues:**
- Port conflicts (9100, 9256, 9115)
- Firewall blocking metrics ports
- Insufficient permissions

## Module Dependencies

```
core/ → networking/ → security/
  ↓         ↓           ↓
performance/ → monitoring/ → validation/
  ↓
virtualisation/
```

## Quick Commands

```bash
# Rebuild with new global config
sudo nixos-rebuild switch

# Test configuration without applying
sudo nixos-rebuild test

# Boot with new configuration
sudo nixos-rebuild boot

# Check what will change
sudo nixos-rebuild dry-activate

# View current configuration
nix show-config

# Search for options
nixos-option networking.firewall.enable
```

## Best Practices Checklist

- [ ] Use `lib.mkDefault` for overridable values
- [ ] Use `lib.mkForce` for values that should override host settings
- [ ] Add validation assertions for critical configurations
- [ ] Test changes on a single host first
- [ ] Document non-obvious configurations
- [ ] Keep modules focused on single responsibilities
- [ ] Use descriptive module names
- [ ] Update README.md when adding new modules
