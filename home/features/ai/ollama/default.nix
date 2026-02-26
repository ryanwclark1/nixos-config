{
  config,
  pkgs,
  ...
}:
# Ollama service configured via home-manager for woody only
# ROCm acceleration enabled for AMD GPU support
# ROCm packages are configured in hosts/woody/performance.nix
# This module is only imported in home/woody.nix, ensuring it's not available on other hosts
{
  services.ollama = {
    enable = true;
    port = 11434;
    host = "0.0.0.0";
    acceleration = "rocm"; # AMD GPU acceleration via ROCm
    # Note: loadModels is not available in home-manager's ollama module
    # Models should be loaded manually via: ollama pull <model-name>
    # Or configured via NixOS module in hosts/common/optional/services/ollama.nix
  };
}
