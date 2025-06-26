{
  pkgs,
  config,
  lib,
  ...
}:
let
  # Helper function to create secure directories
  createSecureDir = path: {
    "${path}" = {
      mode = "0750";
      user = "alloy";
      group = "alloy";
    };
  };
in
{
  # Create the Alloy configuration file with enhanced features
  environment.etc."alloy/config.alloy".source = pkgs.writeText "config.alloy" ''
    // =============================================================================
    // Grafana Alloy Configuration for Log Collection and Metrics
    // =============================================================================

    // Global configuration
    global {
      log_level = "info"
      server {
        log_level = "info"
        http_listen_port = 12345
        http_listen_address = "127.0.0.1"
      }
    }

    // =============================================================================
    // LOKI CONFIGURATION
    // =============================================================================

    // Loki write component for sending logs to Loki with retry and timeout
    loki.write "local" {
      endpoint {
        url = "http://woody:3100/loki/api/v1/push"
        timeout = "10s"
        retry_on_failure {
          enabled = true
          initial_delay = "1s"
          max_delay = "30s"
          max_retries = 10
        }
      }
      external_labels = {
        "host" = "woody"
        "component" = "alloy"
        "environment" = "production"
      }
    }

    // =============================================================================
    // PROMETHEUS CONFIGURATION
    // =============================================================================

    // Prometheus remote write for metrics with retry and timeout
    prometheus.remote_write "local" {
      endpoint {
        url = "http://woody:9090/api/v1/write"
        timeout = "10s"
        retry_on_failure {
          enabled = true
          initial_delay = "1s"
          max_delay = "30s"
          max_retries = 10
        }
      }
      external_labels = {
        "host" = "woody"
        "component" = "alloy"
        "environment" = "production"
      }
    }

    // =============================================================================
    // RELABELING RULES
    // =============================================================================

    // Enhanced relabel rules for journal logs
    loki.relabel "journal" {
      forward_to = []

      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
      rule {
        source_labels = ["__journal__boot_id"]
        target_label  = "boot_id"
      }
      rule {
        source_labels = ["__journal__transport"]
        target_label  = "transport"
      }
      rule {
        source_labels = ["__journal_priority_keyword"]
        target_label  = "level"
      }
      rule {
        source_labels = ["__journal__hostname"]
        target_label  = "instance"
      }
      rule {
        source_labels = ["__journal__machine_id"]
        target_label  = "machine_id"
      }
      rule {
        source_labels = ["__journal__user_id"]
        target_label  = "user_id"
      }
      rule {
        source_labels = ["__journal__user_name"]
        target_label  = "user_name"
      }
      rule {
        source_labels = ["__journal__session_id"]
        target_label  = "session_id"
      }
      rule {
        source_labels = ["__journal__slice"]
        target_label  = "slice"
      }
      rule {
        source_labels = ["__journal__invocation_id"]
        target_label  = "invocation_id"
      }
      rule {
        source_labels = ["__journal__message_id"]
        target_label  = "message_id"
      }
      rule {
        source_labels = ["__journal__cursor"]
        target_label  = "cursor"
      }
      rule {
        source_labels = ["__journal__realtime_timestamp"]
        target_label  = "realtime_timestamp"
      }
      rule {
        source_labels = ["__journal__monotonic_timestamp"]
        target_label  = "monotonic_timestamp"
      }
    }

    // Relabel rules for file logs
    loki.relabel "file_logs" {
      forward_to = []

      rule {
        source_labels = ["__path__"]
        target_label  = "file_path"
      }
      rule {
        source_labels = ["__filename__"]
        target_label  = "filename"
      }
      rule {
        source_labels = ["__path__"]
        regex = ".*/([^/]+)\\.log"
        target_label  = "service"
        replacement = "$1"
      }
    }

    // =============================================================================
    // LOG SOURCES
    // =============================================================================

    // Journal source for reading systemd journal logs with enhanced relabeling
    loki.source.journal "read" {
      forward_to = [
        loki.write.local.receiver,
      ]
      relabel_rules = loki.relabel.journal.rules
      labels = {
        "job" = "journal"
        "host" = "woody"
        "component" = "alloy"
        "source" = "systemd-journal"
      }
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

    // Enhanced file source patterns for application logs
    local.file_match "applogs" {
      path_targets = [
        // System logs
        {"__path__" = "/var/log/*.log"},
        {"__path__" = "/var/log/syslog"},
        {"__path__" = "/var/log/auth.log"},
        {"__path__" = "/var/log/kern.log"},
        {"__path__" = "/var/log/dmesg"},
        {"__path__" = "/var/log/daemon.log"},
        {"__path__" = "/var/log/messages"},

        // Application specific logs
        {"__path__" = "/var/log/nginx/*.log"},
        {"__path__" = "/var/log/apache2/*.log"},
        {"__path__" = "/var/log/mysql/*.log"},
        {"__path__" = "/var/log/postgresql/*.log"},

        // Docker logs
        {"__path__" = "/var/lib/docker/containers/*/*.log"},

        // Custom application logs
        {"__path__" = "/var/log/applications/*.log"},
        {"__path__" = "/opt/*/logs/*.log"},

        // Security logs
        {"__path__" = "/var/log/audit/audit.log"},
        {"__path__" = "/var/log/fail2ban.log"},

        // Network logs
        {"__path__" = "/var/log/ufw.log"},
        {"__path__" = "/var/log/iptables.log"},
      ]
    }

    // File source for reading application logs with enhanced configuration
    loki.source.file "local_files" {
      targets = local.file_match.applogs.targets
      forward_to = [
        loki.write.local.receiver,
      ]
      relabel_rules = loki.relabel.file_logs.rules
      labels = {
        "job" = "varlogs"
        "host" = "woody"
        "component" = "alloy"
        "source" = "file"
      }
      // Enhanced file reading configuration
      positions_directory = "/var/lib/alloy/positions"
      encoding = "utf-8"
      follow_symlinks = true
      read_from_beginning = false
      // Rate limiting to prevent overwhelming the system
      rate_limiter {
        enabled = true
        rate = 10000
        burst = 20000
      }
    }

    // Docker container logs source
    local.file_match "docker_logs" {
      path_targets = [
        {"__path__" = "/var/lib/docker/containers/*/*.log"},
      ]
    }

    loki.source.file "docker" {
      targets = local.file_match.docker_logs.targets
      forward_to = [
        loki.write.local.receiver,
      ]
      relabel_rules = loki.relabel.file_logs.rules
      labels = {
        "job" = "docker"
        "host" = "woody"
        "component" = "alloy"
        "source" = "docker"
      }
      positions_directory = "/var/lib/alloy/positions"
      encoding = "utf-8"
      follow_symlinks = true
      read_from_beginning = false
    }

    // =============================================================================
    // METRICS COLLECTION
    // =============================================================================

    // Prometheus scrape for Alloy's own metrics with enhanced configuration
    prometheus.scrape "alloy" {
      targets = [
        {
          "__address__" = "127.0.0.1:12345",
          "job" = "alloy",
        },
      ]
      forward_to = [
        prometheus.remote_write.local.receiver,
      ]
      scrape_interval = "15s"
      scrape_timeout = "10s"
      honor_labels = true
      honor_timestamps = true
      metrics_path = "/metrics"
      scheme = "http"
    }

    // Node exporter for comprehensive system metrics
    prometheus.exporter.unix "node" {
      enabled_collectors = [
        "cpu"
        "diskstats"
        "filesystem"
        "loadavg"
        "meminfo"
        "netdev"
        "netstat"
        "textfile"
        "time"
        "uname"
        "vmstat"
        "logind"
        "systemd"
        "interrupts"
        "ksmd"
        "processes"
        "stat"
        "tcpstat"
        "wifi"
        "xfs"
        "zfs"
        "bonding"
        "conntrack"
        "diskstats"
        "entropy"
        "filefd"
        "hwmon"
        "infiniband"
        "ipvs"
        "mdadm"
        "meminfo_numa"
        "mountstats"
        "nfs"
        "nfsd"
        "sockstat"
        "supervisord"
        "systemd"
        "tcpstat"
        "textfile"
        "time"
        "uname"
        "vmstat"
        "wifi"
        "xfs"
        "zfs"
      ]
    }

    prometheus.scrape "linux_node" {
      targets = prometheus.exporter.unix.node.targets
      forward_to = [
        prometheus.remote_write.local.receiver,
      ]
      scrape_interval = "15s"
      scrape_timeout = "10s"
      honor_labels = true
      honor_timestamps = true
      metrics_path = "/metrics"
      scheme = "http"
    }

    // Process exporter for detailed process monitoring
    prometheus.exporter.process "processes" {
      process_names = [
        "{{.Comm}}"
        "{{.ExeBase}}"
        "{{.Matches}}"
      ]
      procfs = "/proc"
      cgroupfs = "/sys/fs/cgroup"
      smaps = true
      threads = true
      gopsutil = true
    }

    prometheus.scrape "processes" {
      targets = prometheus.exporter.process.processes.targets
      forward_to = [
        prometheus.remote_write.local.receiver,
      ]
      scrape_interval = "15s"
      scrape_timeout = "10s"
      honor_labels = true
      honor_timestamps = true
      metrics_path = "/metrics"
      scheme = "http"
    }

    // Systemd exporter for service monitoring
    prometheus.exporter.systemd "systemd" {
      unit_whitelist = [".*"]
      unit_blacklist = [
        "(autovt@|dev-mapper|sys-devices|sys-subsystem|user@|session)\.(service|socket)"
      ]
      enable_restarts_metrics = true
      enable_start_time_metrics = true
      enable_task_metrics = true
    }

    prometheus.scrape "systemd" {
      targets = prometheus.exporter.systemd.systemd.targets
      forward_to = [
        prometheus.remote_write.local.receiver,
      ]
      scrape_interval = "15s"
      scrape_timeout = "10s"
      honor_labels = true
      honor_timestamps = true
      metrics_path = "/metrics"
      scheme = "http"
    }

    // =============================================================================
    // LOG PROCESSING AND FILTERING
    // =============================================================================

    // Log processing pipeline for enhanced log analysis
    loki.process "log_processing" {
      forward_to = [loki.write.local.receiver]

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

      stage.labels {
        values = {
          level = ""
          service = ""
          trace_id = ""
          user_id = ""
          request_id = ""
        }
      }

      stage.timestamp {
        source = "timestamp"
        format = "RFC3339Nano"
      }
    }

    // =============================================================================
    // ALERTING AND MONITORING
    // =============================================================================

    // Self-monitoring for Alloy health
    prometheus.scrape "alloy_self" {
      targets = [
        {
          "__address__" = "127.0.0.1:12345",
          "job" = "alloy_self",
        },
      ]
      forward_to = [
        prometheus.remote_write.local.receiver,
      ]
      scrape_interval = "30s"
      scrape_timeout = "10s"
      honor_labels = true
      honor_timestamps = true
      metrics_path = "/metrics"
      scheme = "http"
    }
  '';

  # Create alloy user and group with enhanced security
  users.users.alloy = {
    isSystemUser = true;
    group = "alloy";
    home = "/var/lib/alloy";
    createHome = true;
    shell = "${pkgs.bash}/bin/bash";
    extraGroups = [
      "systemd-journal"
      "docker"
    ];
  };

  users.groups.alloy = { };

  # Create necessary directories with proper permissions
  systemd.tmpfiles.rules = [
    # Main data directory
    "d /var/lib/alloy 0750 alloy alloy -"
    "d /var/lib/alloy/positions 0750 alloy alloy -"
    "d /var/lib/alloy/cache 0750 alloy alloy -"
    "d /var/lib/alloy/tmp 0750 alloy alloy -"

    # Log directory
    "d /var/log/alloy 0750 alloy alloy -"

    # Config directory
    "d /etc/alloy 0750 alloy alloy -"
  ];

  # Create custom systemd service for Alloy with enhanced configuration
  systemd.services.alloy = {
    description = "Grafana Alloy - Log Collection Agent";
    documentation = [ "https://grafana.com/docs/alloy/" ];
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "docker.service"
    ];
    wants = [ "network.target" ];
    enable = true;

    serviceConfig = {
      Type = "simple";
      User = "alloy";
      Group = "alloy";
      WorkingDirectory = "/var/lib/alloy";
      ExecStart = "${pkgs.grafana-alloy}/bin/alloy run /etc/alloy/config.alloy";
      ExecReload = "${pkgs.util-linux}/bin/kill -HUP $MAINPID";
      Restart = "always";
      RestartSec = "10";
      # StartLimitInterval = "60s";
      StartLimitBurst = "3";
      StandardOutput = "journal";
      StandardError = "journal";
      SyslogIdentifier = "alloy";

      # Security settings
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [
        "/var/lib/alloy"
        "/var/log"
        "/var/lib/docker"
        "/proc"
        "/sys"
      ];
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;

      # Resource limits
      LimitNOFILE = "65536";
      LimitNPROC = "4096";

      # Environment variables
      Environment = [
        "ALLOY_HOME=/var/lib/alloy"
        "ALLOY_CONFIG=/etc/alloy/config.alloy"
      ];
    };

    # Service dependencies
    unitConfig = {
      RequiresMountsFor = "/var/log /var/lib/docker";
    };
  };

  # Add Alloy to the monitoring group for access to system metrics
  users.groups.monitoring = {
    members = [ "alloy" ];
  };

  # Create logrotate configuration for Alloy logs
  services.logrotate.settings.alloy = {
    files = "/var/log/alloy/*.log";
    compress = true;
    copytruncate = true;
    daily = true;
    rotate = 7;
    missingok = true;
    notifempty = true;
    create = "0640 alloy alloy";
  };
}
