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
        smtp_smarthost = "localhost:587";
        smtp_from = "alertmanager@woody";
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
          }
          {
            match = {
              component = "alloy";
            };
            receiver = "alloy.alerts";
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "2h";
          }
          {
            match = {
              component = "security";
            };
            receiver = "security.alerts";
            group_wait = "10s";
            group_interval = "2m";
            repeat_interval = "30m";
          }
          {
            match = {
              component = "network";
            };
            receiver = "network.alerts";
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "1h";
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
        ];
      };

      receivers = [
        {
          name = "web.hook";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/";
              send_resolved = true;
            }
          ];
        }
        {
          name = "critical.alerts";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/critical";
              send_resolved = true;
            }
          ];
          email_configs = [
            {
              to = "admin@woody";
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
        }
        {
          name = "security.alerts";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/security";
              send_resolved = true;
            }
          ];
          email_configs = [
            {
              to = "security@woody";
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
          name = "container.alerts";
          webhook_configs = [
            {
              url = "http://127.0.0.1:5001/container";
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
