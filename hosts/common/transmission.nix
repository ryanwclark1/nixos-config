{
  pkgs,
  lib,
  config,
  ...
}:
# rpc whitelist set to localhost only, needs to be changed if accessing elsewhere
# If firewall enabled open ports
with lib; {
  options.transmission.enable = mkEnableOption "transmission settings";

  config = mkIf config.transmission.enable {

    services.transmission = {
      enable = true;
      # credentialsFile = "/var/lib/secrets/transmission/settings.json";
      home = "/var/lib/transmission";
      openRPCPort = true; #Open firewall for RPC
      settings = {
        alt-speed-enabled = false;
        bind-address-ipv4 = "0.0.0.0";
        blocklist-enabled = false;
        dht-enabled = true;
        download-dir = "/var/lib/transmission/Downloads";
        download-queue-enabled = true;
        download-queue-size = 5;
        encryption = 1;
        idle-seeding-limit = 30;
        idle-seeding-limit-enabled = false;
        incomplete-dir = "/var/lib/transmission/.incomplete";
        incomplete-dir-enabled = true;
        message-level = 2;
        peer-id-ttl-hours = 6;
        peer-limit-global = 200;
        peer-limit-per-torrent = 50;
        peer-port = 6881;
        peer-port-random-high = 65535;
        peer-port-random-low = 49152;
        peer-port-random-on-start = false;
        peer-socket-tos = "default";
        pex-enabled = true;
        port-forwarding-enabled = false;
        preallocation = 1;
        prefetch-enabled = true;
        queue-stalled-enabled = true;
        queue-stalled-minutes = 30;
        ratio-limit = 0;
        ratio-limit-enabled = true;
        rename-partial-files = true;
        rpc-authentication-required = true;
        rpc-bind-address = "0.0.0.0";
        rpc-enabled = true;
        rpc-host-whitelist-enabled = true;
        rpc-port = 9091;
        rpc-url = "/transmission/";
        rpc-whitelist = "127.0.0.1,::1";
        scrape-paused-torrents-enabled = true;
        seed-queue-enabled = false;
        seed-queue-size = 10;
        speed-limit-down = 100;
        speed-limit-down-enabled = false;
        speed-limit-up = 100;
        speed-limit-up-enabled = true;
        start-added-torrents = true;
        trash-original-torrent-files = true;
        watch-dir = "/var/lib/transmission/watch-dir";
        watch-dir-enabled = true;
        umask = 18;
      };
    };
  };


}