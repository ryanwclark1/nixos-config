{

  ...
}:
# if nixpkgs.config.rocmSupport is enabled, uses "rocm"
{
  networking.firewall = {
    allowedTCPPorts = [
      11434 # ollama
    ];
  };

  services.ollama = {
    enable = true;
    port = 11434;
    host = "0.0.0.0";
    acceleration = "rocm";
  };
}
