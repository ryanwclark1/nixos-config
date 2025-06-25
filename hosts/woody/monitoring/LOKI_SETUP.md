# Loki and Grafana Alloy Setup Guide

This guide covers the complete setup of Loki (log aggregation) and Grafana Alloy (log collection) for centralized log monitoring across woody and frametop.

## Architecture Overview

```
┌─────────────┐    ┌─────────────┐
│   frametop  │    │    woody    │
│             │    │             │
│ Grafana     │    │ Grafana     │
│ Alloy       │    │ Alloy       │
│ (Client)    │    │ (Client)    │
└─────┬───────┘    └─────┬───────┘
      │                  │
      └──────────────────┼─────────┐
                         │         │
                    ┌────▼────┐    │
                    │  Loki   │    │
                    │(Server) │    │
                    └────┬────┘    │
                         │         │
                    ┌────▼────┐    │
                    │ Grafana │    │
                    │(UI)     │    │
                    └─────────┘    │
                                   │
                    ┌──────────────┘
                    │
                    ▼
              ┌─────────────┐
              │  Prometheus │
              │ (Metrics)   │
              └─────────────┘
```

## Components

### 1. Loki Server (woody)
- **Purpose**: Centralized log storage and querying
- **Port**: 3100
- **Storage**: Local filesystem with TSDB
- **Retention**: 30 days
- **Access**: HTTP API for log ingestion and queries

### 2. Grafana Alloy (woody & frametop)
- **Purpose**: Log collection and forwarding
- **Port**: 12345 (metrics), 12346 (gRPC)
- **Functions**:
  - Collects system journal logs
  - Collects /var/log files
  - Collects Docker container logs
  - Collects Nginx logs
  - Collects application logs
  - Forwards logs to Loki
  - Exposes metrics for Prometheus

### 3. Grafana (woody)
- **Purpose**: Log visualization and exploration
- **Port**: 3001
- **Features**:
  - Loki data source integration
  - Log exploration dashboards
  - Multi-host log comparison
  - Templating variables for filtering

## Configuration Files

### Loki Configuration (`hosts/woody/monitoring/loki.nix`)
- Server settings (port 3100)
- TSDB storage configuration
- Retention policies (30 days)
- Ingester and compactor settings

### Grafana Alloy Configuration (`hosts/common/global/monitoring/grafana-alloy.nix`)
- Log collection jobs:
  - `journal`: Systemd journal logs
  - `varlogs`: /var/log files
  - `docker`: Docker container logs
  - `nginx`: Nginx logs
  - `applications`: Custom application logs
- Loki client configuration
- Metrics exposure for Prometheus

### Grafana Configuration (`hosts/woody/monitoring/grafana.nix`)
- Loki data source addition
- Dashboard provisioning
- Log exploration dashboards

## Log Sources

### System Journal (journald)
- **Path**: `/run/log/journal`
- **Labels**: `job=journal`, `host=<hostname>`, `unit=<service>`, `priority=<level>`
- **Content**: All systemd service logs, boot logs, kernel logs

### System Logs (/var/log)
- **Path**: `/var/log/*log`
- **Labels**: `job=varlogs`, `host=<hostname>`
- **Content**: Traditional log files, application logs

### Docker Container Logs
- **Path**: `/var/lib/docker/containers/*/*log`
- **Labels**: `job=docker`, `host=<hostname>`
- **Content**: All Docker container stdout/stderr

### Nginx Logs
- **Path**: `/var/log/nginx/*.log`
- **Labels**: `job=nginx`, `host=<hostname>`
- **Content**: Nginx access and error logs

### Application Logs
- **Path**: `/var/log/apps/*.log`
- **Labels**: `job=applications`, `host=<hostname>`
- **Content**: Custom application logs

## Dashboards

### 1. Log Exploration Dashboard (`log-exploration.json`)
- **UID**: `log-exploration`
- **Purpose**: Comprehensive log exploration
- **Panels**:
  - System journal logs
  - System logs from /var/log
  - Docker container logs
  - Nginx logs
  - Application logs
  - Error logs across all sources
- **Variables**: Host, Job

### 2. Multi-Host Log Dashboard (`multi-host-logs.json`)
- **UID**: `multi-host-logs`
- **Purpose**: Multi-host log comparison
- **Panels**:
  - All logs by host
  - Error logs by host
  - System journal by host
  - Docker logs by host
  - System logs by host
  - Systemd unit logs by host
- **Variables**: Host, Systemd Unit

## Deployment Steps

### 1. Deploy to Woody (Server)
```bash
# Build and deploy woody configuration
sudo nixos-rebuild switch --flake .#woody
```

### 2. Deploy to Frametop (Client)
```bash
# Build and deploy frametop configuration
sudo nixos-rebuild switch --flake .#frametop
```

### 3. Verify Services
```bash
# Check Loki on woody
systemctl status loki
curl http://woody:3100/ready

# Check Alloy on both hosts
systemctl status alloy
curl http://localhost:12345/metrics

# Check Grafana
systemctl status grafana
curl http://woody:3001/api/health
```

## Usage

### Accessing Logs

1. **Grafana UI**: Navigate to `http://woody:3001`
2. **Default Credentials**: admin/admin
3. **Dashboards**:
   - "Log Exploration Dashboard" for general log exploration
   - "Multi-Host Log Dashboard" for cross-host comparison

### Log Queries

#### Basic Queries
```logql
# All logs from woody
{host="woody"}

# Error logs only
{priority="err"}

# Docker logs
{job="docker"}

# System journal logs
{job="journal"}
```

#### Advanced Queries
```logql
# Nginx error logs from woody
{host="woody", job="nginx"} |= "error"

# Failed systemd services
{job="journal", unit=~".*service"} |= "Failed"

# Docker logs containing "error" or "exception"
{job="docker"} |~ "(?i)(error|exception)"

# Logs from last 5 minutes
{job="journal"} [5m]
```

### Variables

- **$host**: Filter by hostname (woody, frametop)
- **$job**: Filter by job type (journal, varlogs, docker, nginx, applications)
- **$unit**: Filter by systemd unit name

## Monitoring

### Service Health
- **Loki**: `http://woody:3100/ready`
- **Alloy**: `http://localhost:12345/metrics`
- **Grafana**: `http://woody:3001/api/health`

### Metrics
- Alloy metrics are scraped by Prometheus
- Available in Grafana under Prometheus data source
- Job names: `woody-alloy`, `frametop-alloy`

### Log Volume
- Monitor log ingestion rate in Loki metrics
- Check Alloy scrape success/failure metrics
- Monitor disk usage for log storage

## Troubleshooting

### Common Issues

#### 1. No Logs in Loki
```bash
# Check Alloy service
systemctl status alloy

# Check Alloy configuration
cat /etc/alloy/config.alloy

# Check Alloy logs
journalctl -u alloy -f

# Verify log files exist
ls -la /var/log/
ls -la /run/log/journal/
```

#### 2. Loki Not Receiving Logs
```bash
# Check Loki service
systemctl status loki

# Check Loki readiness
curl http://woody:3100/ready

# Check Loki logs
journalctl -u loki -f

# Verify network connectivity
curl http://woody:3100/loki/api/v1/status/buildinfo
```

#### 3. Grafana Can't Connect to Loki
```bash
# Check data source configuration
# In Grafana: Configuration > Data Sources > Loki

# Verify URL: http://localhost:3100
# Test connection from Grafana UI
```

#### 4. High Log Volume
```bash
# Check log retention settings
# Adjust in loki.nix: limits_config.retention_period

# Monitor disk usage
df -h /var/lib/loki/

# Check log file sizes
du -sh /var/log/*
```

### Performance Tuning

#### 1. Log Retention
- Adjust retention period in `loki.nix`
- Default: 30 days
- Consider reducing for high-volume environments

#### 2. Scrape Intervals
- Alloy scrape interval: 15s (default)
- Adjust in Alloy config if needed

#### 3. Storage Optimization
- Loki uses TSDB for better performance
- Monitor disk usage and I/O
- Consider SSD storage for better performance

## Security Considerations

### Network Security
- Loki listens on all interfaces (0.0.0.0:3100)
- Consider restricting to private network only
- Use firewall rules to limit access

### Authentication
- Loki auth is disabled by default
- Consider enabling authentication for production
- Use reverse proxy with authentication if needed

### Log Privacy
- Be aware of sensitive data in logs
- Consider log filtering and sanitization
- Implement log retention policies

## Future Enhancements

### Planned Features
- [ ] Add log parsing and structured logging
- [ ] Implement log alerting rules
- [ ] Add log backup and archiving
- [ ] Create custom log dashboards for specific applications
- [ ] Add log correlation with metrics
- [ ] Implement log sampling for high-volume sources

### Scalability
- [ ] Consider distributed Loki deployment
- [ ] Add log aggregation for multiple servers
- [ ] Implement log streaming for real-time analysis
- [ ] Add log compression and optimization

## Support

For issues and questions:
1. Check service logs: `journalctl -u <service> -f`
2. Verify configuration files
3. Test network connectivity
4. Check Grafana and Loki documentation
5. Review this setup guide

## References

- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Grafana Alloy Documentation](https://grafana.com/docs/agent/latest/)
- [LogQL Query Language](https://grafana.com/docs/loki/latest/logql/)
- [Grafana Dashboard Documentation](https://grafana.com/docs/grafana/latest/dashboards/)
