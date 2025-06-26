# Grafana Dashboards

This directory contains Grafana dashboard JSON files that are automatically provisioned when Grafana starts.

## Available Dashboards

### Metrics Dashboards

1. **node-exporter.json** (UID: `node-exporter`)
   - **Purpose**: System metrics from Node Exporter
   - **Tags**: `node-exporter`, `system`, `monitoring`
   - **Coverage**: CPU, memory, disk, network, load, system info
   - **Usage**: Monitor system performance and health

2. **systemd-services.json** (UID: `systemd-services`)
   - **Purpose**: Systemd service states and health
   - **Tags**: `systemd`, `services`, `monitoring`
   - **Coverage**: Service states, active/inactive counts, failed services
   - **Usage**: Monitor systemd service health and status

3. **process-monitoring.json** (UID: `process-monitoring`)
   - **Purpose**: Process-level metrics
   - **Tags**: `process`, `monitoring`
   - **Coverage**: CPU, memory, threads, I/O per process
   - **Usage**: Monitor specific processes and resource usage

4. **enhanced-node-exporter.json** (UID: `enhanced-node-exporter`)
   - **Purpose**: Enhanced system metrics with detailed breakdowns
   - **Tags**: `node-exporter`, `enhanced`, `monitoring`
   - **Coverage**: Detailed CPU, memory, disk, network metrics
   - **Usage**: Deep system analysis and troubleshooting

5. **enhanced-container-monitoring.json** (UID: `enhanced-container-monitoring`)
   - **Purpose**: Detailed container metrics from cAdvisor
   - **Tags**: `cadvisor`, `containers`, `monitoring`
   - **Coverage**: CPU, memory, network, disk, working set, cache
   - **Usage**: Monitor Docker containers and resource usage

6. **docker-monitoring.json** (UID: `docker-monitoring`)
   - **Purpose**: Basic Docker container monitoring
   - **Tags**: `docker`, `containers`, `monitoring`
   - **Coverage**: Container CPU, memory, network usage
   - **Usage**: Basic container monitoring

7. **overview-dashboard.json** (UID: `overview-dashboard`)
   - **Purpose**: High-level overview of all systems
   - **Tags**: `overview`, `monitoring`
   - **Coverage**: Key metrics from all exporters
   - **Usage**: Quick system health overview

8. **multi-machine-dashboard.json** (UID: `multi-machine-dashboard`)
   - **Purpose**: Multi-host comparison and aggregated metrics
   - **Tags**: `multi-host`, `comparison`, `monitoring`
   - **Coverage**: Side-by-side host comparisons, aggregated metrics
   - **Usage**: Compare performance across hosts

### Log Dashboards

9. **log-exploration.json** (UID: `log-exploration`)
   - **Purpose**: Comprehensive log exploration and analysis
   - **Tags**: `logs`, `loki`, `monitoring`
   - **Coverage**: System journal, /var/log, Docker, Nginx, application logs
   - **Usage**: Explore and analyze logs from various sources
   - **Features**:
     - System journal logs
     - System logs from /var/log
     - Docker container logs
     - Nginx logs
     - Application logs
     - Error logs across all sources
     - Host and job templating variables

10. **multi-host-logs.json** (UID: `multi-host-logs`)
    - **Purpose**: Multi-host log comparison and analysis
    - **Tags**: `logs`, `loki`, `monitoring`, `multi-host`
    - **Coverage**: Logs from woody and frametop with filtering
    - **Usage**: Compare and analyze logs across multiple hosts
    - **Features**:
      - All logs by host
      - Error logs by host
      - System journal by host
      - Docker logs by host
      - System logs by host
      - Systemd unit logs by host
      - Host and unit templating variables

### Alloy Monitoring Dashboards

11. **alloy-overview.json** (UID: `alloy-overview`)
    - **Purpose**: Grafana Alloy log collection agent monitoring
    - **Tags**: `alloy`, `logs`, `monitoring`
    - **Coverage**: Alloy build info, journal logs rate, file logs rate, logs sent to Loki
    - **Usage**: Monitor Alloy's performance and log collection metrics
    - **Features**:
      - Alloy build information
      - Journal logs collection rate
      - File logs collection rate
      - Logs sent to Loki rate
      - Real-time monitoring of log collection pipeline

## Data Sources

- **Prometheus**: Metrics from all exporters (Node Exporter, Systemd Exporter, cAdvisor, Process Exporter, Alloy)
- **Loki**: Logs from Grafana Alloy (journald, /var/log, Docker, Nginx, applications)

## Usage Instructions

1. **Access Dashboards**: Navigate to Grafana at `http://woody:3001`
2. **Default Credentials**: admin/admin (change in production!)
3. **Dashboard Selection**: Use the dashboard dropdown or search by name/tags
4. **Time Range**: Adjust using the time picker in the top right
5. **Variables**: Use templating variables (host, job, unit) to filter data
6. **Refresh**: Dashboards auto-refresh every 10 seconds

## Log Queries

### Basic Log Queries
- `{job="journal"}` - System journal logs
- `{job="varlogs"}` - System logs from /var/log
- `{job="docker"}` - Docker container logs
- `{priority="err"}` - Error logs only

### Advanced Log Queries
- `{host="woody", job="journal"}` - Journal logs from woody
- `{unit="nginx.service"}` - Nginx service logs
- `{job="docker"} |= "error"` - Docker logs containing "error"
- `{job="journal"} | json` - JSON-formatted journal logs

## Troubleshooting

### Dashboard Not Loading
1. Check if Prometheus is running: `systemctl status prometheus`
2. Check if Loki is running: `systemctl status loki`
3. Verify data sources in Grafana: Configuration > Data Sources
4. Check dashboard files exist: `ls /var/lib/grafana/dashboards/`

### No Data in Dashboards
1. Verify exporters are running:
   - `systemctl status prometheus-node-exporter`
   - `systemctl status prometheus-systemd-exporter`
   - `systemctl status prometheus-cadvisor`
   - `systemctl status prometheus-process-exporter`
   - `systemctl status alloy`
2. Check Prometheus targets: `http://woody:9090/targets`
3. Verify Loki is receiving logs: `http://woody:3100/ready`

### No Logs in Loki
1. Check Alloy is running: `systemctl status alloy`
2. Verify Alloy config: `cat /etc/alloy/config.alloy`
3. Check Alloy logs: `journalctl -u alloy -f`
4. Verify log files exist and are readable

## Customization

### Adding New Dashboards
1. Create JSON file in this directory
2. Set unique UID in the JSON
3. Add appropriate tags
4. Restart Grafana or wait for auto-provisioning

### Modifying Existing Dashboards
1. Edit the JSON file
2. Restart Grafana or wait for auto-provisioning
3. Changes are preserved in the JSON files

### Adding New Data Sources
1. Update `hosts/woody/monitoring/grafana.nix`
2. Add to the `datasources` list
3. Rebuild and deploy

## Architecture Notes

### Dashboard Provisioning
- All dashboards are stored as JSON files in this directory
- Grafana automatically provisions them on startup via the file provider
- No hardcoded dashboards in Nix configuration - all are external JSON files
- This allows for easier version control and dashboard sharing

### Host-Specific Configuration
- Dashboard configuration is now host-specific (woody) rather than global
- Each host can have its own set of dashboards
- Configuration is more modular and maintainable

## Future Enhancements

- [ ] Add alerting rules for critical metrics
- [ ] Create custom dashboards for specific applications
- [ ] Add log parsing and structured logging support
- [ ] Implement log retention policies
- [ ] Add authentication and authorization
- [ ] Create backup and restore procedures
- [ ] Add performance optimization for large log volumes
- [ ] Create dashboard templates for new hosts
