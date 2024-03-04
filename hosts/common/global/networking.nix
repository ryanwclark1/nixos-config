{
  ...
}:

{
  networking = {
    networkmanager = {
      enable = true;
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
