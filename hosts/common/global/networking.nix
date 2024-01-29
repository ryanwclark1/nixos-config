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
      "9.9.9.9"
      "1.1.1.1"
    ];
  };
}