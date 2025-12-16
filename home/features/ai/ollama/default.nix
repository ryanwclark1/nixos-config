{
  ...
}:
# if nixpkgs.config.rocmSupport is enabled, uses "rocm"
{
  services.ollama = {
    enable = true;
    port = 11434;
    host = "0.0.0.0";
    acceleration = "rocm";
  };
}
