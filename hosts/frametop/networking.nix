# ./host/frametop/networking.nix

{
  # Networking.
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true;
  networking.firewall.enable = false;
  networking.hostName = "frametop";
  networking.nameservers = ["10.10.100.1" "9.9.9.9" "1.1.1.1"];
  # networking.networkmanager.enable = true;
  # networking.defaultGateway = "10.10.100.1";
}