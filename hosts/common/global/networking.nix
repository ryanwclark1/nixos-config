{
  config,
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
}
