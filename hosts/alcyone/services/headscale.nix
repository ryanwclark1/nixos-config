{ config, lib, ... }:
let
  derpPort = 3478;
in
{
  services = {
    headscale = {
      enable = true;
      port = 8085;
      address = "127.0.0.1";
      settings = {
        dns_config = {
          override_local_dns = true;
          base_domain = "techcasa.io";
          magic_dns = true;
          domains = [ "ts.techcasa.io" ];
          nameservers = [
            "9.9.9.9"
          ];
        };
        server_url = "https://tailscale.techcasa.io";
        metrics_listen_addr = "127.0.0.1:8095";
        logtail = {
          enabled = false;
        };
        log = {
          level = "warn";
        };
        ip_prefixes = [
          "100.64.0.0/10"
          "fdef:6567:bd7a::/48"
        ];
        derp.server = {
          enable = true;
          region_id = 999;
          stun_listen_addr = "0.0.0.0:${toString derpPort}";
        };
      };
    };

    nginx.virtualHosts = {
      "tailscale.techcasa.io" = {
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://localhost:${toString config.services.headscale.port}";
            proxyWebsockets = true;
          };
          "/metrics" = {
            proxyPass = "http://${config.services.headscale.settings.metrics_listen_addr}/metrics";
          };
        };
      };
      "tailscale.techcasa.io" = {
        forceSSL = true;
        enableACME = true;
        locations."/".return = "302 https://tailscale.techcasa.io$request_uri";
      };
    };
  };

  # Derp server
  networking.firewall.allowedUDPPorts = [ derpPort ];


  environment.systemPackages = [ config.services.headscale.package ];

  environment.persistence = {
    "/persist".directories = [ "/var/lib/headscale" ];
  };
}
