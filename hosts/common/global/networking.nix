{
  ...
}:

{
  networking = {
    networkmanager = {
      enable = true;
    };
    firewall = {
      enable = true;
    };
    nameservers = [
      "10.10.100.1"
      "1.1.1.1"
      "1.0.0.1"
    ];
  };
}
