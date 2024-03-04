{
  ...
}:

{
  networking = {
    networkmanager = {
      enable = true;
      dns = "default";
      appendNameservers = [
        "10.10.100.1"
        "1.1.1.1"
        "1.0.0.1"
      ];
      logLevel = "DEBUG";
    };
    firewall = {
      enable = true;
    };

  };
}
