# Woody Monitoring Setup

This directory contains the comprehensive monitoring configuration for the Woody server using Grafana Alloy, Prometheus, Grafana, and Alertmanager.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Data Sources  │    │   Grafana Alloy │    │   Storage       │
│                 │    │                 │    │                 │
│ • System Metrics│───▶│ • Collection    │───▶│ • Prometheus    │
│ • Container Logs│    │ • Processing    │    │ • Loki          │
│ • Network SNMP  │    │ • Relabeling    │    │                 │
│ • Blackbox Probes│   │ • Remote Write  │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Grafana       │
                       │                 │
                       │ • Dashboards    │
                       │ • Alerting      │
                       │ • Visualization │
                       └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Alertmanager  │
                       │                 │
                       │ • Notifications │
                       │ • Routing       │
                       │ • Grouping      │
                       └─────────────────┘
```

## Components

### 1. Grafana Alloy (`config.alloy`)
- **Purpose**: Central data collection and processing agent
- **Features**:
  - System metrics collection via Unix exporter
  - Container monitoring via cAdvisor
  - Network device monitoring via SNMP
  - Network connectivity monitoring via Blackbox
  - Comprehensive log collection and processing
  - Advanced relabeling and processing pipelines

### 2. Prometheus
- **Purpose**: Time-series metrics storage and querying
- **Port**: 9090
- **Features**:
  - Metrics storage
  - Alert rule evaluation
  - Service discovery

### 3. Grafana
- **Purpose**: Visualization and alerting interface
- **Port**: 3001
- **Features**:
  - Dashboard visualization
  - Unified alerting
  - Log exploration
  - Multi-datasource queries

### 4. Alertmanager
- **Purpose**: Alert routing and notification management
- **Port**: 9093
- **Features**:
  - Alert grouping and deduplication
  - Multi-channel notifications
  - Time-based routing
  - Inhibition rules

## Dashboards

### System Monitoring
- **Enhanced Alloy Overview**: Alloy health, performance, and data flow
- **Enhanced Node Exporter**: Comprehensive system metrics
- **Process Monitoring**: Detailed process-level monitoring
- **Systemd Services**: Service health and status

### Container Monitoring
- **Enhanced Container Monitoring**: Docker container metrics and health
- **Docker Monitoring**: Container resource usage and performance

### Network Monitoring
- **Network Monitoring**: SNMP device status, Blackbox probes, connectivity
- **Security Monitoring**: Authentication events, firewall logs, security alerts

### Logging
- **Log Exploration**: Interactive log querying and analysis
- **Multi-Host Logs**: Cross-host log correlation and analysis

### Overview
- **Overview Dashboard**: High-level system overview
- **Multi-Machine Dashboard**: Multi-host monitoring view

## Alerting Rules

### Alloy Health (`alloy-health.yml`)
- Alloy process health monitoring
- Configuration reload failures
- Remote write failures
- Resource usage alerts

### System Metrics (`system-metrics.yml`)
- CPU, memory, and disk usage
- Network interface status
- Systemd service failures
- Load average monitoring

### Container Metrics (`container-metrics.yml`)
- Container health and status
- Resource usage alerts
- OOM events
- Restart rate monitoring

### Network Monitoring (`network-monitoring.yml`)
- SNMP device connectivity
- Interface errors and utilization
- Blackbox probe failures
- SSL certificate expiry

### Log Monitoring (`log-monitoring.yml`)
- High error rates
- Security events (failed logins, brute force)
- Service restart loops
- Database connection errors

## Alerting Configuration

### Routing Rules
- **Critical Alerts**: Immediate notification with email
- **Security Alerts**: Fast notification for security events
- **Alloy Alerts**: Dedicated routing for monitoring system
- **Network Alerts**: Network-specific notification handling
- **Container Alerts**: Container-specific notification handling

### Notification Channels
- **Webhook**: HTTP notifications to external systems
- **Email**: SMTP-based email notifications
- **Time-based**: Different handling for workdays/weekends

### Inhibition Rules
- Critical alerts suppress warning alerts for same component
- Alloy down suppresses other Alloy-related alerts
- Container down suppresses container-specific alerts

## Operational Procedures

### Daily Monitoring Tasks
1. **Check Alloy Health**: Verify Alloy is running and collecting data
2. **Review Alert History**: Check for any alerts that fired
3. **Validate Data Flow**: Ensure metrics and logs are flowing
4. **Check Resource Usage**: Monitor system resource consumption

### Weekly Maintenance Tasks
1. **Dashboard Review**: Update dashboards based on usage patterns
2. **Alert Rule Tuning**: Adjust thresholds based on historical data
3. **Log Analysis**: Review log patterns and adjust processing rules
4. **Performance Review**: Analyze monitoring system performance

### Monthly Tasks
1. **Capacity Planning**: Review storage and resource requirements
2. **Security Review**: Audit access and review security events
3. **Backup Verification**: Ensure monitoring data is backed up
4. **Documentation Update**: Update runbooks and procedures

## Troubleshooting

### Common Issues

#### Alloy Not Starting
```bash
# Check Alloy logs
journalctl -u alloy -f

# Verify configuration
alloy check-config /etc/alloy/config.alloy

# Check file permissions
ls -la /etc/alloy/
```

#### Missing Metrics
```bash
# Check Alloy targets
curl http://localhost:12345/api/v1/targets

# Verify exporters are running
systemctl status prometheus-exporter-unix
systemctl status prometheus-exporter-cadvisor
```

#### Alertmanager Not Sending Notifications
```bash
# Check Alertmanager status
curl http://localhost:9093/api/v1/status

# Verify configuration
alertmanager --config.file=/etc/alertmanager/alertmanager.yml --check-config
```

#### Grafana Dashboard Issues
```bash
# Check Grafana logs
journalctl -u grafana -f

# Verify datasource connectivity
curl http://localhost:3001/api/datasources
```

### Performance Tuning

#### Alloy Performance
- Adjust scrape intervals based on monitoring needs
- Optimize relabeling rules for better performance
- Monitor memory usage and adjust limits

#### Storage Optimization
- Configure retention policies for metrics and logs
- Use recording rules for frequently queried metrics
- Implement log aggregation and archiving

#### Network Optimization
- Use local caching for frequently accessed data
- Optimize SNMP polling intervals
- Configure appropriate timeouts for probes

## Security Considerations

### Access Control
- Use strong authentication for Grafana
- Implement role-based access control
- Regular security audits of monitoring data

### Data Protection
- Encrypt sensitive monitoring data
- Implement proper log retention policies
- Regular backup of monitoring configuration

### Network Security
- Use SNMP community strings other than 'public'
- Implement proper firewall rules
- Monitor for suspicious access patterns

## Configuration Files

### Alloy Configuration
- `config.alloy`: Main Alloy configuration
- `snmp.yml`: SNMP exporter configuration
- `blackbox.yml`: Blackbox exporter configuration

### Grafana Configuration
- `grafana.nix`: Grafana service configuration
- `dashboards/`: Dashboard JSON files
- `provisioning/`: Datasource and dashboard provisioning

### Alerting Configuration
- `alertmanager.nix`: Alertmanager service configuration
- `grafana/provisioning/alerting/rules/`: Alert rule files
- `grafana/provisioning/alerting/prometheus.yml`: Prometheus alerting config

## Monitoring Best Practices

### Metrics Collection
- Use consistent labeling across all metrics
- Implement proper cardinality management
- Regular validation of metric collection

### Alerting
- Set appropriate thresholds based on historical data
- Use proper alert grouping and inhibition
- Implement escalation procedures

### Logging
- Use structured logging where possible
- Implement proper log levels
- Regular log analysis and pattern recognition

### Documentation
- Keep runbooks updated
- Document configuration changes
- Maintain troubleshooting guides

## Support and Maintenance

### Regular Updates
- Keep monitoring components updated
- Review and update alert rules
- Maintain dashboard relevance

### Capacity Planning
- Monitor storage growth
- Plan for scaling requirements
- Regular performance reviews

### Disaster Recovery
- Backup monitoring configurations
- Document recovery procedures
- Test recovery processes regularly
