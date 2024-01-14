{ config, ... }:
{
  services = {
    prometheus = {
      enable = true;
      globalConfig = {
        # Scrape a bit more frequently
        scrape_interval = "30s";
      };
      scrapeConfigs = [
        {
          job_name = "hydra";
          scheme = "https";
          static_configs = [{
            targets = [ "hydra.techcasa.io" ];
          }];
        }
        {
          job_name = "headscale";
          scheme = "https";
          static_configs = [{
            targets = [ "tailscale.techcasa.io" ];
          }];
        }
        {
          job_name = "nginx";
          scheme = "https";
          static_configs = [{
            targets = [ "alcyone.techcasa.io" "celaeno.techcasa.io" "merope.techcasa.io" ];
          }];
        }
      ];
      extraFlags = let prometheus = config.services.prometheus.package;
      in [
        # Custom consoles
        "--web.console.templates=${prometheus}/etc/prometheus/consoles"
        "--web.console.libraries=${prometheus}/etc/prometheus/console_libraries"
      ];
    };
    nginx.virtualHosts = {
      "metrics.techcasa.io" = {
        forceSSL = true;
        enableACME = true;
        locations."/".proxyPass =
          "http://localhost:${toString config.services.prometheus.port}";
      };
    };
  };
}
