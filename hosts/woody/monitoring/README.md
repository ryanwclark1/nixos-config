# Monitoring Stack Setup

This directory contains the monitoring stack configuration for woody and frametop.

## Architecture

- **woody**: Central monitoring server with Prometheus, Grafana, and Alertmanager
- **frametop**: Client with exporters only
- **Communication**: Secure communication via Tailscale network

## Services

### On woody (Central Server)

1. **Prometheus** (Port 9090)
   - URL: http://woody:9090
   - Collects metrics from both woody and frametop via Tailscale
   - Scrapes exporters every 15 seconds
   - Integrated with Alertmanager

2. **Grafana** (Port 3001)
   - URL: http://woody:3001
   - Default credentials: admin/admin
   - Pre-configured with Prometheus data source
   - Dashboard provisioning enabled

3. **Alertmanager** (Port 9093)
   - URL: http://woody:9093
   - Handles alert routing and notifications
   - Webhook receiver configured

### Exporters (Both woody and frametop)

1. **Node Exporter** (Port 9100)
   - System metrics (CPU, memory, disk, network, etc.)
   - Comprehensive collector configuration including network metrics

2. **Systemd Exporter** (Port 9558)
   - Systemd service metrics
   - Monitors all services except slices

3. **cAdvisor** (Port 8080)
   - Container metrics (Docker, Kubernetes, etc.)
   - Provides detailed container resource usage
   - Replaces the non-existent Docker exporter

4. **Process Exporter** (Port 9256)
   - Process-specific metrics
   - Monitors monitoring stack processes

## Access

After deployment:

1. **Prometheus**: http://woody:9090
2. **Grafana**: http://woody:3001 (admin/admin)
3. **Alertmanager**: http://woody:9093

## Security

- All exporter communication is secured via Tailscale
- Firewall rules only allow access on Tailscale interface
- No ports exposed to public internet

## Firewall Configuration

The following ports are opened on Tailscale interface only:
- 9090: Prometheus
- 3001: Grafana
- 9093: Alertmanager
- 9100: Node Exporter
- 9558: Systemd Exporter
- 8080: cAdvisor
- 9256: Process Exporter

## Next Steps

1. Deploy the configuration
2. Access Grafana and change the default password
3. Import useful dashboards:
   - Node Exporter Full: 1860
   - Docker and System Monitoring: 893
   - Systemd Services: 9578
4. Configure Alertmanager notifications
5. Set up custom alerts as needed

## Useful Grafana Dashboards

- Node Exporter Full: 1860
- Docker and System Monitoring: 893
- Systemd Services: 9578
- Process Monitoring: 249
- cAdvisor: 14282

## Alerting

Alertmanager is configured with:
- Webhook receiver for notifications
- Grouping by alertname, cluster, and service
- Inhibition rules to prevent alert spam
- 30s initial wait, 5m grouping interval, 4h repeat interval

## Container Monitoring

cAdvisor provides comprehensive container metrics including:
- CPU usage per container
- Memory usage and limits
- Network I/O statistics
- Disk I/O metrics
- Container lifecycle events

## Network Monitoring

Network metrics are collected by the Node Exporter, which includes:
- Network interface statistics
- Network device metrics
- Network protocol statistics
- Connection tracking information
