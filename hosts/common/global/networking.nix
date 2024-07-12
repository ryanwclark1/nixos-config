{
  config,
  ...
}:
# let
#   inherit (config.networking) hostName;
# in
{
  networking = {
    networkmanager = {
      enable = true;
      dns = "default";
      appendNameservers = [
        "100.100.100.100"
        "10.10.100.1"
        "1.1.1.1"
        "1.0.0.1"
      ];
      logLevel = "DEBUG";
    };
    firewall = {
      enable = true;
    };
    domain = "techcasa.io";
    fqdn = "${config.networking.hostName}.${config.networking.domain}";
    search = [
      "${config.networking.domain}"
    ];
  };
}
