{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.alloy-unified;
  
  # Generate the Alloy configuration from template
  alloyConfig = pkgs.writeText "config.alloy" (
    builtins.replaceStrings
      [
        "\${hostname}"
        "\${lokiEndpoint}"
        "\${prometheusEndpoint}"
        "\${environment}"
        "\${volumeFilterConfig}"
        "\${journalForwardTo}"
        "\${customConfig}"
      ]
      [
        cfg.hostname
        cfg.lokiEndpoint
        cfg.prometheusEndpoint
        cfg.environment
        cfg.volumeFilterConfig
        cfg.journalForwardTo
        cfg.customConfig
      ]
      (builtins.readFile ./alloy/config.alloy.tmpl)
  );

  # Volume filter configuration for hosts that need it
  volumeFilterStanza = ''
    // Volume filter for journal logs to reduce ingestion rate
    loki.relabel "journal_volume_filter" {
      forward_to = [
        loki.process.journal_parser.receiver,
      ]

      // Drop debug and info level logs to reduce volume
      rule {
        source_labels = ["__journal_priority"]
        regex         = "[5-7]" // 5=notice, 6=info, 7=debug
        action        = "drop"
      }

      // Drop noisy services that generate too many logs
      rule {
        source_labels = ["__journal__systemd_unit"]
        regex         = "(systemd-journal|systemd-logind|NetworkManager|chronyd|audit)\\.service"
        action        = "drop"
      }

      // Also drop repetitive kernel messages (info/debug only)
      rule {
        source_labels = ["__journal__comm", "__journal_priority"]
        regex         = "kernel;[6-7]"
        separator     = ";"
        action        = "drop"
      }

      // Drop Alloy process discovery permission errors
      rule {
        source_labels = ["__journal__systemd_unit", "__journal__message"]
        regex         = "alloy\\.service;.*failed to get process info.*permission denied.*"
        separator     = ";"
        action        = "drop"
      }
    }
  '';

in {
  options.services.alloy-unified = {
    enable = mkEnableOption "Grafana Alloy unified configuration";

    hostname = mkOption {
      type = types.str;
      description = "Hostname for this Alloy instance";
      default = config.networking.hostName;
    };

    lokiEndpoint = mkOption {
      type = types.str;
      description = "Loki endpoint URL";
      example = "http://localhost:3100/loki/api/v1/push";
    };

    prometheusEndpoint = mkOption {
      type = types.str;
      description = "Prometheus endpoint URL";
      default = "http://woody:9090/api/v1/write";
    };

    environment = mkOption {
      type = types.str;
      description = "Environment label";
      default = "production";
    };

    enableVolumeFilter = mkOption {
      type = types.bool;
      description = "Enable volume filtering for journal logs";
      default = false;
    };

    journalForwardTo = mkOption {
      type = types.str;
      description = "Forward target for journal logs";
      default = "loki.relabel.journal.receiver,";
    };

    customConfig = mkOption {
      type = types.lines;
      description = "Additional custom configuration";
      default = "";
    };

    extraCapabilities = mkOption {
      type = types.listOf types.str;
      description = "Additional capabilities for the Alloy service";
      default = [];
    };
  };

  config = mkIf cfg.enable {
    # Create directories
    systemd.tmpfiles.rules = [
      "d /etc/alloy 0755 alloy alloy -"
      "d /var/lib/alloy 0755 alloy alloy -"
      "d /var/lib/alloy/data 0755 alloy alloy -"
    ];

    # Create configuration files
    environment.etc = {
      "alloy/config.alloy" = {
        source = alloyConfig;
        mode = "0640";
        user = "alloy";
        group = "alloy";
      };
      "alloy/blackbox.yml" = {
        source = ./alloy/blackbox.yml;
        mode = "0640";
        user = "alloy";
        group = "alloy";
      };
      "alloy/snmp.yml" = {
        source = ./alloy/snmp.yml;
        mode = "0640";
        user = "alloy";
        group = "alloy";
      };
    };

    # Configure the Alloy service
    systemd.services.alloy = {
      description = "Grafana Alloy";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        Type = "simple";
        User = "alloy";
        Group = "alloy";
        ExecStart = "${pkgs.grafana-alloy}/bin/alloy run /etc/alloy --disable-reporting";
        Restart = "always";
        RestartSec = "5s";
        WorkingDirectory = "/var/lib/alloy";
        
        # Security settings
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/var/lib/alloy" ];
        ReadOnlyPaths = [ "/etc/alloy" "/var/log" "/run/log/journal" ];
        
        # Capabilities
        AmbientCapabilities = [
          "CAP_SYS_PTRACE"
          "CAP_DAC_READ_SEARCH"
        ] ++ cfg.extraCapabilities;
        
        # Resource limits
        LimitNOFILE = "65535";
        LimitNPROC = "4096";
      };
    };

    # User and group
    users.users.alloy = {
      isSystemUser = true;
      group = "alloy";
      home = "/var/lib/alloy";
      createHome = true;
      description = "Grafana Alloy user";
      extraGroups = [ "systemd-journal" "docker" ];
    };

    users.groups.alloy = {};

    # Open firewall
    networking.firewall.allowedTCPPorts = [ 12345 ];

    # Apply volume filter configuration if enabled
    services.alloy-unified = {
      volumeFilterConfig = if cfg.enableVolumeFilter then volumeFilterStanza else "";
      journalForwardTo = if cfg.enableVolumeFilter 
        then "loki.relabel.journal_volume_filter.receiver,"
        else "loki.relabel.journal.receiver,";
    };
  };
}