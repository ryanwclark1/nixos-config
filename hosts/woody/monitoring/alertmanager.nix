{
  pkgs,
  config,
  ...
}:

{
  environment.etc."grafana/provisioning/alerting/prometheus.yml" = {
    source = ./grafana/provisioning/alerting/prometheus.yml;
  };

  environment.etc."grafana/provisioning/alerting/rules/alloy-health.yml" = {
    source = ./grafana/provisioning/alerting/rules/alloy-health.yml;
  };

  environment.etc."grafana/provisioning/alerting/rules/container-metrics.yml" = {
    source = ./grafana/provisioning/alerting/rules/container-metrics.yml;
  };


  services.prometheus.alertmanager = {
    enable = true;
    port = 9093;
    webExternalUrl = "http://woody:9093/";

    configuration = {
      global = {
        resolve_timeout = "5m";
      };

      templates = [
        "/etc/alertmanager/templates/*.tmpl"
      ];

      route = {
        group_by = [
          "alertname"
          "cluster"
          "service"
          "component"
          "severity"
        ];
        group_wait = "30s";
        group_interval = "5m";
        repeat_interval = "4h";
        receiver = "web.hook";

        routes = [
          {
            match = {
              severity = "critical";
            };
            receiver = "critical.alerts";
            group_wait = "10s";
            group_interval = "2m";
            repeat_interval = "1h";
            continue = true;
          }
          {
            match = {
              severity = "critical";
              component = "database";
            };
            receiver = "database.oncall";
            group_wait = "5s";
            group_interval = "1m";
            repeat_interval = "30m";
          }
          {
            match = {
              component = "alloy";
            };
            receiver = "alloy.alerts";
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "2h";
            routes = [
              {
                match = {
                  alertname = "AlloyConfigError";
                };
                receiver = "alloy.config.alerts";
                group_wait = "10s";
              }
            ];
          }
          {
            match = {
              component = "security";
            };
            receiver = "security.alerts";
            group_wait = "10s";
            group_interval = "2m";
            repeat_interval = "30m";
            routes = [
              {
                match = {
                  security_type = "brute_force";
                };
                receiver = "security.urgent";
                group_wait = "5s";
                repeat_interval = "15m";
              }
              {
                match = {
                  security_type = "firewall";
                };
                receiver = "security.firewall";
                group_wait = "30s";
              }
            ];
          }
          {
            match = {
              component = "network";
            };
            receiver = "network.alerts";
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "1h";
            routes = [
              {
                match = {
                  alertname = "SSLCertificateExpiry";
                };
                receiver = "ssl.alerts";
                group_wait = "1m";
                repeat_interval = "12h";
              }
            ];
          }
          {
            match = {
              component = "container";
            };
            receiver = "container.alerts";
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "2h";
          }
          {
            match = {
              environment = "production";
            };
            receiver = "production.alerts";
            group_wait = "15s";
            group_interval = "3m";
            repeat_interval = "1h";
            mute_time_intervals = [ "maintenance" ];
          }
          {
            match = {
              environment = "staging";
            };
            receiver = "staging.alerts";
            group_wait = "1m";
            group_interval = "10m";
            repeat_interval = "4h";
            active_time_intervals = [ "workdays" ];
          }
          {
            match = {
              severity = "info";
            };
            receiver = "info.alerts";
            group_wait = "5m";
            group_interval = "30m";
            repeat_interval = "12h";
          }
          {
            match_re = {
              service = "(prometheus|grafana|loki)";
            };
            receiver = "monitoring.alerts";
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "2h";
          }
        ];
      };

      receivers = [
        {
          name = "web.hook";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/";
              send_resolved = true;
              http_config = {
                bearer_token = "default-webhook-token";
              };
            }
          ];
        }
        {
          name = "critical.alerts";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/critical";
              send_resolved = true;
              max_alerts = 10;
              http_config = {
                bearer_token = "critical-webhook-token";
              };
            }
          ];
        }
        {
          name = "database.oncall";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/database/critical";
              send_resolved = true;
            }
          ];
        }
        {
          name = "alloy.alerts";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/alloy";
              send_resolved = true;
            }
          ];
          slack_configs = [
            {
              api_url = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK";
              channel = "#monitoring-alerts";
              title = "Alloy Alert";
              text = "{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}";
            }
          ];
        }
        {
          name = "alloy.config.alerts";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/alloy/config";
              send_resolved = true;
            }
          ];
        }
        {
          name = "security.alerts";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/security";
              send_resolved = true;
            }
            {
              url = "http://127.0.0.1:5003/siem";
              send_resolved = false;
            }
          ];
        }
        {
          name = "security.urgent";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/security/urgent";
              send_resolved = true;
              max_alerts = 5;
            }
          ];
        }
        {
          name = "security.firewall";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/security/firewall";
              send_resolved = true;
            }
          ];
        }
        {
          name = "network.alerts";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/network";
              send_resolved = true;
            }
          ];
        }
        {
          name = "ssl.alerts";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/ssl";
              send_resolved = true;
            }
          ];
        }
        {
          name = "container.alerts";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/container";
              send_resolved = true;
            }
          ];
          slack_configs = [
            {
              api_url = "https://hooks.slack.com/services/YOUR/CONTAINER/WEBHOOK";
              channel = "#container-alerts";
              title = "Container Alert";
              text = "{{ .GroupLabels.container_name }} - {{ .CommonAnnotations.summary }}";
            }
          ];
        }
        {
          name = "production.alerts";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/production";
              send_resolved = true;
              http_config = {
                bearer_token = "prod-webhook-token";
              };
            }
          ];
        }
        {
          name = "staging.alerts";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/staging";
              send_resolved = true;
            }
          ];
          slack_configs = [
            {
              api_url = "https://hooks.slack.com/services/YOUR/STAGING/WEBHOOK";
              channel = "#staging-alerts";
            }
          ];
        }
        {
          name = "info.alerts";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/info";
              send_resolved = false;
            }
          ];
        }
        {
          name = "monitoring.alerts";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/monitoring";
              send_resolved = true;
            }
          ];
        }
      ];

      inhibit_rules = [
        {
          source_match = {
            severity = "critical";
          };
          target_match = {
            severity = "warning";
          };
          equal = [
            "alertname"
            "dev"
            "instance"
            "component"
          ];
        }
        {
          source_match = {
            severity = "critical";
          };
          target_match = {
            severity = "info";
          };
          equal = [
            "alertname"
            "instance"
          ];
        }
        {
          source_match = {
            alertname = "AlloyDown";
          };
          target_match = {
            component = "alloy";
          };
          equal = [
            "instance"
          ];
        }
        {
          source_match = {
            alertname = "AlloyConfigError";
          };
          target_match = {
            alertname = "AlloyUnhealthy";
          };
          equal = [
            "instance"
            "job"
          ];
        }
        {
          source_match = {
            alertname = "ContainerDown";
          };
          target_match = {
            component = "container";
          };
          equal = [
            "instance"
            "container_name"
          ];
        }
        {
          source_match = {
            alertname = "NodeDown";
          };
          target_match = {
            alertname = ".*";
          };
          equal = [
            "instance"
          ];
        }
        {
          source_match = {
            alertname = "NetworkInterfaceDown";
          };
          target_match = {
            component = "network";
            severity = "warning";
          };
          equal = [
            "instance"
            "interface"
          ];
        }
        {
          source_match = {
            alertname = "DatabaseDown";
          };
          target_match = {
            component = "application";
          };
          equal = [
            "instance"
            "database"
          ];
        }
        {
          source_match = {
            environment = "production";
            severity = "critical";
          };
          target_match = {
            environment = "production";
            severity = "warning";
          };
          equal = [
            "service"
            "component"
          ];
        }
        {
          source_match = {
            alertname = "DiskSpaceCritical";
          };
          target_match = {
            alertname = "DiskSpaceWarning";
          };
          equal = [
            "instance"
            "mountpoint"
          ];
        }
      ];

      time_intervals = [
        {
          name = "workdays";
          time_intervals = [
            {
              weekdays = [ "monday" "tuesday" "wednesday" "thursday" "friday" ];
              times = [
                {
                  start_time = "09:00";
                  end_time = "17:00";
                }
              ];
            }
          ];
        }
        {
          name = "weekends";
          time_intervals = [
            {
              weekdays = [ "saturday" "sunday" ];
            }
          ];
        }
        {
          name = "office-hours";
          time_intervals = [
            {
              weekdays = [ "monday" "tuesday" "wednesday" "thursday" "friday" ];
              times = [
                {
                  start_time = "08:00";
                  end_time = "18:00";
                }
              ];
            }
          ];
        }
        {
          name = "after-hours";
          time_intervals = [
            {
              weekdays = [ "monday" "tuesday" "wednesday" "thursday" "friday" ];
              times = [
                {
                  start_time = "18:00";
                  end_time = "23:59";
                }
                {
                  start_time = "00:00";
                  end_time = "08:00";
                }
              ];
            }
            {
              weekdays = [ "saturday" "sunday" ];
            }
          ];
        }
        {
          name = "maintenance";
          time_intervals = [
            {
              weekdays = [ "sunday" ];
              times = [
                {
                  start_time = "02:00";
                  end_time = "06:00";
                }
              ];
            }
          ];
        }
        {
          name = "business-critical";
          time_intervals = [
            {
              weekdays = [ "monday" "tuesday" "wednesday" "thursday" "friday" ];
              times = [
                {
                  start_time = "07:00";
                  end_time = "19:00";
                }
              ];
            }
          ];
        }
        {
          name = "overnight";
          time_intervals = [
            {
              times = [
                {
                  start_time = "22:00";
                  end_time = "23:59";
                }
                {
                  start_time = "00:00";
                  end_time = "06:00";
                }
              ];
            }
          ];
        }
        {
          name = "holidays";
          time_intervals = [
            {
              months = [ "december" ];
              days_of_month = [ "25" "26" ];
            }
            {
              months = [ "january" ];
              days_of_month = [ "1" ];
            }
            {
              months = [ "july" ];
              days_of_month = [ "4" ];
            }
          ];
        }
        {
          name = "peak-hours";
          time_intervals = [
            {
              weekdays = [ "monday" "tuesday" "wednesday" "thursday" "friday" ];
              times = [
                {
                  start_time = "10:00";
                  end_time = "12:00";
                }
                {
                  start_time = "14:00";
                  end_time = "16:00";
                }
              ];
            }
          ];
        }
        {
          name = "low-priority-hours";
          time_intervals = [
            {
              weekdays = [ "monday" "tuesday" "wednesday" "thursday" "friday" ];
              times = [
                {
                  start_time = "12:00";
                  end_time = "13:00";
                }
              ];
            }
            {
              weekdays = [ "saturday" "sunday" ];
              times = [
                {
                  start_time = "10:00";
                  end_time = "18:00";
                }
              ];
            }
          ];
        }
      ];
    };
  };

  # Create notification templates
  environment.etc."alertmanager/templates/email.tmpl" = {
    text = ''
      {{ define "email.to.html" }}
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>{{ template "__subject" . }}</title>
      </head>
      <body>
        <h1>{{ template "__subject" . }}</h1>
        <p><strong>Alert:</strong> {{ .GroupLabels.alertname }}</p>
        <p><strong>Severity:</strong> {{ .CommonLabels.severity }}</p>
        <p><strong>Component:</strong> {{ .CommonLabels.component }}</p>
        <p><strong>Instance:</strong> {{ .CommonLabels.instance }}</p>
        <hr>
        {{ range .Alerts }}
        <h2>Alert: {{ .Annotations.summary }}</h2>
        <p>{{ .Annotations.description }}</p>
        <p><strong>Started:</strong> {{ .StartsAt }}</p>
        {{ if .EndsAt }}
        <p><strong>Ended:</strong> {{ .EndsAt }}</p>
        {{ end }}
        <hr>
        {{ end }}
      </body>
      </html>
      {{ end }}
    '';
    mode = "0644";
  };

  # Open firewall for Alertmanager
  networking.firewall.allowedTCPPorts = [ 9093 ];
}
