{
  config,
  lib,
  ...
}:
let
  inherit (config.networking) hostName;
  domain = "techcasa.io";
in
{
  networking = {
    networkmanager = {
      enable = true;
      dns = "default";
      appendNameservers = [
        "10.10.100.1"
        "1.1.1.1"
        "1.0.0.1"
        "100.100.100.100"
      ];
      logLevel = "INFO";
    };
    firewall = {
      enable = true;
      allowPing = true;
    };
    fqdn = "${hostName}.${domain}";
    search = [
      "${domain}"
    ];
  };

  # Causes long boots and hangs on update
  # https://github.com/NixOS/nixpkgs/issues/180175#issuecomment-1473408913
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

}
