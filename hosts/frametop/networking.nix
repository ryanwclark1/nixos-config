# ./host/frametop/networking.nix

{
  lib,
  ...
}:

# TODO: update wireguard config and use mkDefault to override
{
  networking = lib.mkDefault {
    hostName = "frametop";
    networkmanager.enable = true;
    firewall.enable = false;
    nameservers = [
      "10.10.100.1"
      "9.9.9.9"
      "1.1.1.1"
    ];
    # defaultGateway = "10.10.100.1";
    wireguard.enable = true;
  };
}