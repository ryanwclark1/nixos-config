# Enhanced Grafana Alloy Configuration

This document describes the enhanced Grafana Alloy configuration for comprehensive log collection and metrics monitoring.

## Overview

The enhanced Alloy configuration provides:
- **Comprehensive log collection** from multiple sources
- **Advanced metrics collection** with multiple exporters
- **Enhanced security** with proper isolation and permissions
- **Reliability features** with retry logic and error handling
- **Performance optimization** with rate limiting and resource management
- **Structured logging** with JSON parsing and label extraction

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Log Sources   │    │   Alloy Agent   │    │   Destinations  │
│                 │    │                 │    │                 │
│ • systemd       │───▶│ • Log Processing│───▶│ • Loki          │
│ • /var/log      │    │ • Metrics       │    │ • Prometheus    │
│ • Docker        │    │ • Relabeling    │    │                 │
│ • Applications  │    │ • Filtering     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Key Enhancements

### 1. **Enhanced Security**

#### User and Group Configuration
- Dedicated `alloy` user with minimal privileges
- Proper home directory (`/var/lib/alloy`)
- Membership in required groups (`systemd-journal`, `docker`, `monitoring`)

#### Systemd Security Features
```nix
# Security hardening
NoNewPrivileges = true;
ProtectSystem = "strict";
ProtectHome = true;
PrivateTmp = true;
PrivateDevices = true;
ProtectKernelTunables = true;
ProtectKernelModules = true;
ProtectControlGroups = true;
RestrictRealtime = true;
RestrictSUIDSGID = true;
LockPersonality = true;
MemoryDenyWriteExecute = true;
```

#### Directory Permissions
- All directories created with `0750` permissions
- Proper ownership by `alloy:alloy`
- Minimal read/write access paths

### 2. **Comprehensive Log Collection**

#### Systemd Journal Logs
```river
loki.source.journal "read" {
  // Enhanced journal configuration
  journal {
    json = false
    max_age = "12h"
    path = "/var/log/journal"
    matches = [
      "_SYSTEMD_UNIT=systemd-*"
      "_SYSTEMD_UNIT=*.service"
      "_SYSTEMD_UNIT=*.socket"
      "_SYSTEMD_UNIT=*.timer"
    ]
  }
}
```

#### File Logs
Comprehensive coverage including:
- **System logs**: `/var/log/*.log`, `syslog`, `auth.log`, `kern.log`
- **Application logs**: nginx, apache2, mysql, postgresql
- **Docker logs**: `/var/lib/docker/containers/*/*.log`
- **Security logs**: audit, fail2ban
- **Network logs**: ufw, iptables
- **Custom logs**: `/var/log/applications/*.log`, `/opt/*/logs/*.log`

#### Docker Container Logs
Separate configuration for Docker logs with proper labeling:
```river
loki.source.file "docker" {
  labels = {
    "job" = "docker"
    "host" = "woody"
    "component" = "alloy"
    "source" = "docker"
  }
}
```

### 3. **Advanced Metrics Collection**

#### Node Exporter
Comprehensive system metrics with all collectors enabled:
- CPU, memory, disk, network statistics
- Systemd service states
- Process information
- Hardware monitoring (hwmon, interrupts)
- File system and mount statistics
- Network stack details (conntrack, sockstat)

#### Process Exporter
Detailed process monitoring:
```river
prometheus.exporter.process "processes" {
  process_names = [
    "{{.Comm}}"
    "{{.ExeBase}}"
    "{{.Matches}}"
  ]
  smaps = true
  threads = true
  gopsutil = true
}
```

#### Systemd Exporter
Service monitoring with enhanced features:
```river
prometheus.exporter.systemd "systemd" {
  unit_whitelist = [".*"]
  unit_blacklist = [
    "(autovt@|dev-mapper|sys-devices|sys-subsystem|user@|session)\.(service|socket)"
  ]
  enable_restarts_metrics = true
  enable_start_time_metrics = true
  enable_task_metrics = true
}
```

### 4. **Enhanced Relabeling**

#### Journal Log Relabeling
Extensive metadata extraction:
- `unit`, `boot_id`, `transport`, `level`
- `user_id`, `user_name`, `session_id`
- `slice`, `invocation_id`, `message_id`
- `cursor`, `realtime_timestamp`, `monotonic_timestamp`

#### File Log Relabeling
```river
loki.relabel "file_logs" {
  rule {
    source_labels = ["__path__"]
    target_label  = "file_path"
  }
  rule {
    source_labels = ["__path__"]
    regex = ".*/([^/]+)\\.log"
    target_label  = "service"
    replacement = "$1"
  }
}
```

### 5. **Log Processing Pipeline**

#### JSON Log Parsing
```river
loki.process "log_processing" {
  stage.json {
    expressions = {
      level = "level"
      timestamp = "timestamp"
      message = "message"
      service = "service"
      trace_id = "trace_id"
      user_id = "user_id"
      request_id = "request_id"
    }
  }
}
```

#### Label Extraction
Automatic extraction of structured fields as labels for better querying.

### 6. **Reliability Features**

#### Retry Logic
```river
retry_on_failure {
  enabled = true
  initial_delay = "1s"
  max_delay = "30s"
  max_retries = 10
}
```

#### Rate Limiting
```river
rate_limiter {
  enabled = true
  rate = 10000
  burst = 20000
}
```

#### Resource Limits
- File descriptor limit: 65536
- Process limit: 4096
- Memory and CPU limits via systemd

### 7. **Performance Optimization**

#### File Reading Configuration
```river
positions_directory = "/var/lib/alloy/positions"
encoding = "utf-8"
follow_symlinks = true
read_from_beginning = false
```

#### Scraping Configuration
- Optimized scrape intervals (15s for most, 30s for self-monitoring)
- Proper timeouts and honor settings
- Efficient target discovery

## Configuration Sections

### 1. Global Configuration
```river
global {
  log_level = "info"
  server {
    log_level = "info"
    http_listen_port = 12345
    http_listen_address = "127.0.0.1"
  }
}
```

### 2. Loki Configuration
- Endpoint configuration with retry logic
- External labels for consistent tagging
- Timeout and failure handling

### 3. Prometheus Configuration
- Remote write with retry logic
- External labels for consistent tagging
- Optimized scraping settings

### 4. Log Sources
- **Journal**: systemd journal with enhanced filtering
- **Files**: comprehensive file log collection
- **Docker**: container log collection

### 5. Metrics Collection
- **Node Exporter**: comprehensive system metrics
- **Process Exporter**: detailed process monitoring
- **Systemd Exporter**: service state monitoring
- **Self-monitoring**: Alloy health metrics

### 6. Log Processing
- JSON parsing for structured logs
- Label extraction for better querying
- Timestamp parsing and normalization

## Monitoring and Alerting

### Self-Monitoring
Alloy exposes its own metrics for monitoring:
- Log collection rates
- Error rates and failures
- Resource usage
- Health status

### Key Metrics to Monitor
- `alloy_build_info` - Alloy version and build information
- `loki_source_journal_targets_total` - Journal log collection rate
- `loki_source_file_targets_total` - File log collection rate
- `loki_write_sent_bytes_total` - Logs sent to Loki
- `prometheus_remote_write_samples_total` - Metrics sent to Prometheus

## Log Queries

### Basic Queries
```logql
# All journal logs
{job="journal"}

# All file logs
{job="varlogs"}

# Docker logs
{job="docker"}

# Error logs
{level="error"}
```

### Advanced Queries
```logql
# Service-specific logs
{unit="nginx.service"}

# User-specific logs
{user_name="admin"}

# Time-based filtering
{job="journal"} | json | timestamp > "2024-01-01T00:00:00Z"

# Structured log parsing
{job="varlogs"} | json | level="error"
```

## Troubleshooting

### Common Issues

#### 1. Permission Denied
```bash
# Check user permissions
sudo -u alloy ls -la /var/log
sudo -u alloy ls -la /var/lib/docker

# Verify group membership
groups alloy
```

#### 2. Service Not Starting
```bash
# Check service status
systemctl status alloy

# View logs
journalctl -u alloy -f

# Check configuration
sudo -u alloy alloy check /etc/alloy/config.alloy
```

#### 3. No Logs in Loki
```bash
# Check Alloy metrics
curl http://127.0.0.1:12345/metrics | grep loki

# Verify Loki connectivity
curl http://woody:3100/ready

# Check file positions
ls -la /var/lib/alloy/positions/
```

#### 4. High Resource Usage
```bash
# Check resource limits
systemctl show alloy | grep Limit

# Monitor process
top -p $(pgrep alloy)

# Check file descriptors
lsof -p $(pgrep alloy) | wc -l
```

### Debugging Commands

#### Configuration Validation
```bash
# Validate configuration
sudo -u alloy alloy check /etc/alloy/config.alloy

# Test configuration
sudo -u alloy alloy run --dry-run /etc/alloy/config.alloy
```

#### Metrics Inspection
```bash
# View Alloy metrics
curl http://127.0.0.1:12345/metrics

# Check specific metrics
curl http://127.0.0.1:12345/metrics | grep -E "(loki|prometheus)"
```

#### Log Analysis
```bash
# View Alloy logs
journalctl -u alloy -f

# Check log rotation
ls -la /var/log/alloy/

# Verify log collection
curl http://127.0.0.1:12345/metrics | grep loki_source
```

## Performance Tuning

### Resource Limits
Adjust based on system capacity:
```nix
LimitNOFILE = "65536";  # File descriptors
LimitNPROC = "4096";    # Processes
```

### Rate Limiting
Modify based on log volume:
```river
rate_limiter {
  rate = 10000   # Logs per second
  burst = 20000  # Burst capacity
}
```

### Scrape Intervals
Optimize based on monitoring needs:
```river
scrape_interval = "15s"  # Standard metrics
scrape_interval = "30s"  # Self-monitoring
```

## Security Considerations

### Network Security
- Alloy listens only on `127.0.0.1:12345`
- No external network access required
- Internal communication only

### File System Security
- Minimal read/write paths
- Proper file permissions
- Secure directory structure

### Process Security
- No privilege escalation
- Memory execution protection
- Kernel module protection

## Backup and Recovery

### Configuration Backup
```bash
# Backup configuration
sudo cp /etc/alloy/config.alloy /backup/alloy-config-$(date +%Y%m%d).alloy

# Backup positions
sudo tar -czf /backup/alloy-positions-$(date +%Y%m%d).tar.gz /var/lib/alloy/positions/
```

### Recovery Procedures
```bash
# Restore configuration
sudo cp /backup/alloy-config-YYYYMMDD.alloy /etc/alloy/config.alloy

# Restore positions
sudo tar -xzf /backup/alloy-positions-YYYYMMDD.tar.gz -C /

# Restart service
sudo systemctl restart alloy
```

## Future Enhancements

### Planned Features
- [ ] Log encryption in transit
- [ ] Advanced log filtering and sampling
- [ ] Custom log parsing rules
- [ ] Integration with external alerting systems
- [ ] Log retention policies
- [ ] Performance dashboards
- [ ] Automated configuration validation
- [ ] Health check endpoints

### Monitoring Improvements
- [ ] Custom metrics for application-specific monitoring
- [ ] Advanced alerting rules
- [ ] Performance baselines
- [ ] Capacity planning metrics
- [ ] SLA monitoring

This enhanced configuration provides a robust, secure, and comprehensive logging and monitoring solution for production environments.
