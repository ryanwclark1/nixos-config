# Grafana Alloy Configuration for Woody

This directory contains the modular Grafana Alloy configuration for comprehensive monitoring of the woody server.

## Overview

The configuration is split into logical modules for better maintainability and organization. Each module focuses on a specific aspect of monitoring:

- **Log Collection**: Systemd journal, file logs, Docker container logs
- **Metrics Collection**: System metrics, process monitoring, container metrics
- **Service Discovery**: Dynamic Docker container discovery
- **Log Processing**: Structured data extraction and parsing
- **Remote Write**: Loki and Prometheus endpoint configurations
- **Relabeling**: Label extraction and transformation rules

## Directory Structure

```
alloy/
├── config.alloy              # Main configuration file (imports all modules)
├── modules/                   # Modular configuration components
│   ├── remote-write.river    # Remote write configurations
│   ├── relabeling.river      # All relabeling rules
│   ├── log-sources.river     # Log source configurations
│   ├── metrics-collection.river # Metrics collection components
│   ├── service-discovery.river # Service discovery components
│   └── log-processing.river  # Log processing pipelines
├── blackbox.yml              # Blackbox exporter configuration
├── snmp.yml                  # SNMP exporter configuration
└── README.md                 # This file
```

## Modules

### 1. `remote-write.river`
Contains all remote write configurations:
- **Loki**: Log aggregation with rate limiting and WAL
- **Prometheus**: Metrics forwarding with retry logic

### 2. `relabeling.river`
Contains all relabeling rules for both logs and metrics:
- **Loki Relabeling**: Log filtering, categorization, and label extraction
- **Prometheus Relabeling**: Metrics processing and label management

### 3. `log-sources.river`
Defines all log collection sources:
- **Systemd Journal**: System service logs with filtering
- **File Logs**: Application and system log files
- **Docker Logs**: Container stdout/stderr streams

### 4. `metrics-collection.river`
Contains all metrics collection components:
- **Unix Exporter**: System metrics (CPU, memory, disk, network)
- **Process Exporter**: Process-level monitoring
- **cAdvisor**: Container resource metrics
- **Blackbox**: Network connectivity monitoring
- **Self-monitoring**: Alloy health metrics

### 5. `service-discovery.river`
Handles dynamic service discovery:
- **Docker Discovery**: Automatic container detection
- **Container Metrics**: Scraping metrics from containers
- **Label Management**: Container metadata extraction

### 6. `log-processing.river`
Contains log processing pipelines:
- **JSON Parser**: Structured log extraction
- **Regex Parsers**: Pattern-based data extraction
- **Specialized Parsers**: Auth, firewall, web, database logs

## Configuration Files

### `blackbox.yml`
Blackbox exporter configuration for network probing:
- HTTP/HTTPS health checks
- TCP connectivity tests
- ICMP ping monitoring
- DNS resolution checks

### `snmp.yml`
SNMP exporter configuration for network devices:
- Ubiquiti device monitoring
- Interface statistics
- System information
- Wireless metrics (for UniFi APs)

## Features

### Log Collection
- **Comprehensive Coverage**: Systemd journal, file logs, Docker containers
- **Volume Filtering**: Automatic filtering of noisy logs
- **Structured Processing**: JSON and regex-based parsing
- **Categorization**: Automatic service and log type classification

### Metrics Collection
- **System Metrics**: CPU, memory, disk, network, filesystem
- **Process Monitoring**: Detailed process-level metrics
- **Container Metrics**: Resource usage, performance data
- **Network Monitoring**: Connectivity and availability checks

### Service Discovery
- **Dynamic Discovery**: Automatic container detection
- **Label Extraction**: Container metadata and labels
- **Flexible Scraping**: Support for various metrics endpoints

### Security Features
- **Log Filtering**: Removal of sensitive information
- **Access Control**: Proper user permissions
- **Network Security**: Local-only listening by default

## Usage

### Starting Alloy
```bash
# Check configuration
alloy check /etc/alloy/config.alloy

# Start Alloy service
systemctl start alloy

# View logs
journalctl -u alloy -f
```

### Monitoring Alloy
- **Self-monitoring**: `http://localhost:12345/metrics`
- **Health check**: `http://localhost:12345/ready`
- **Service status**: `systemctl status alloy`

### Configuration Validation
```bash
# Validate main configuration
alloy check /etc/alloy/config.alloy

# Validate individual modules
alloy check /etc/alloy/modules/remote-write.river
alloy check /etc/alloy/modules/relabeling.river
# ... etc
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   # Check user permissions
   sudo -u alloy ls -la /var/log
   sudo -u alloy ls -la /var/lib/docker
   ```

2. **Configuration Errors**
   ```bash
   # Validate configuration
   alloy check /etc/alloy/config.alloy

   # Check syntax
   alloy run --dry-run /etc/alloy/config.alloy
   ```

3. **No Logs in Loki**
   ```bash
   # Check Alloy metrics
   curl http://127.0.0.1:12345/metrics | grep loki

   # Verify Loki connectivity
   curl http://woody:3100/ready
   ```

4. **High Resource Usage**
   ```bash
   # Check resource limits
   systemctl show alloy | grep Limit

   # Monitor process
   top -p $(pgrep alloy)
   ```

### Debugging Commands

```bash
# View Alloy logs
journalctl -u alloy -f

# Check configuration
cat /etc/alloy/config.alloy

# Validate configuration
alloy check /etc/alloy/config.alloy

# Test configuration
alloy run --dry-run /etc/alloy/config.alloy

# Check file positions
ls -la /var/lib/alloy/positions/
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
batch_wait = "5s"       # Batch wait time
batch_size = "1MB"      # Batch size
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
- Remote writes use localhost endpoints
- No external network exposure

### File Permissions
- All directories use `0750` permissions
- Proper ownership by `alloy:alloy`
- Minimal read/write access paths

### Log Security
- Sensitive log filtering in place
- No credential logging
- Audit trail preservation

## Maintenance

### Regular Tasks
1. **Monitor Resource Usage**: Check Alloy's own metrics
2. **Update Targets**: Add/remove monitoring targets as needed
3. **Validate Configuration**: Test after any changes
4. **Review Log Volume**: Monitor ingestion rates
5. **Check Remote Writes**: Verify success rates

### Configuration Updates
1. **Backup**: Always backup before changes
2. **Test**: Validate configuration syntax
3. **Deploy**: Apply changes during maintenance windows
4. **Monitor**: Watch for issues after deployment

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review Alloy documentation: https://grafana.com/docs/alloy/
3. Check system logs: `journalctl -u alloy`
4. Validate configuration: `alloy check /etc/alloy/config.alloy`
