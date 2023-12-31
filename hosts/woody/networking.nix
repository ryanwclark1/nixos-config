# ./host/woody/networking.nix

{
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;
  networking.hostName = "woody";
  networking.nameservers = ["10.10.100.1" "9.9.9.9" "1.1.1.1"];
  # networking.defaultGateway = "10.10.100.1";
}