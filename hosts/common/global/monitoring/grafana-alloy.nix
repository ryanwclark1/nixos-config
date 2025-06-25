{
  pkgs,
  config,
  lib,
  ...
}:
{
  services.alloy = {
    enable = true;
    configPath = "/etc/alloy/config.alloy";
  };

  # Create Alloy configuration directory and config file
  systemd.services.alloy.preStart = ''
    mkdir -p /etc/alloy
    mkdir -p /var/lib/alloy/positions
  '';

  # Create the Alloy configuration file
  environment.etc."alloy/config.alloy".text = ''
    server:
      http_listen_address: 127.0.0.1
      http_listen_port: 12345
      grpc_listen_address: 127.0.0.1
      grpc_listen_port: 12346

    # Log collection configuration
    integrations:
      agent:
        enabled: true

      # Loki client configuration
      loki:
        positions_directory: /var/lib/alloy/positions
        clients:
          - url: http://woody:3100/loki/api/v1/push
            external_labels:
              host: ${config.networking.hostName}
              job: alloy-logs

        scrape_configs:
          # System logs from /var/log
          - job_name: system_logs
            static_configs:
              - targets: [localhost]
                labels:
                  job: varlogs
                  host: ${config.networking.hostName}
                  __path__: /var/log/*log

          # Journald logs
          - job_name: journal
            journal:
              path: /run/log/journal
              max_age: 12h
              json: false
            relabel_configs:
              - source_labels: ['__journal__systemd_unit']
                target_label: 'unit'
              - source_labels: ['__journal__hostname']
                target_label: 'hostname'
              - source_labels: ['__journal__priority']
                target_label: 'priority'
              - source_labels: ['__journal__boot_id']
                target_label: 'boot_id'

          # Docker container logs (if Docker is running)
          - job_name: docker
            static_configs:
              - targets: [localhost]
                labels:
                  job: docker
                  host: ${config.networking.hostName}
                  __path__: /var/lib/docker/containers/*/*log

          # Nginx logs (if nginx is running)
          - job_name: nginx
            static_configs:
              - targets: [localhost]
                labels:
                  job: nginx
                  host: ${config.networking.hostName}
                  __path__: /var/log/nginx/*.log

          # Custom application logs
          - job_name: applications
            static_configs:
              - targets: [localhost]
                labels:
                  job: applications
                  host: ${config.networking.hostName}
                  __path__: /var/log/apps/*.log

    # Metrics collection for Alloy itself
    metrics:
      global:
        scrape_interval: 15s
        evaluation_interval: 15s

      rule_files: []

      scrape_configs:
        - job_name: 'alloy'
          static_configs:
            - targets: ['127.0.0.1:12345']
              labels:
                job: alloy
                host: ${config.networking.hostName}
  '';

  # Set proper permissions and override conflicting settings
  systemd.services.alloy.serviceConfig = {
    User = "alloy";
    Group = "alloy";
    Restart = "always";
    RestartSec = lib.mkForce "10";
  };

  # Create alloy user and group
  users.users.alloy = {
    isSystemUser = true;
    group = "alloy";
    home = "/var/lib/alloy";
    createHome = true;
  };

  users.groups.alloy = { };

  # Ensure directories exist with proper permissions
  systemd.tmpfiles.rules = [
    "d /var/lib/alloy 0755 alloy alloy -"
    "d /var/lib/alloy/positions 0755 alloy alloy -"
    "d /etc/alloy 0755 root root -"
  ];
}
