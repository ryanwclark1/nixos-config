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
    # Pre-load commonly used models
    loadModels = [
      "qwen3:30b-thinking" # PRIMARY: Latest gen + tools + thinking + 256K context (19GB)
      "deepseek-r1:70b"    # O3-level reasoning + tools + thinking (43GB, optimal for hardware)
      "qwen3-coder:30b-a3b-q8_0" # Coding specialist + tools + thinking (32GB, higher precision)
      "magistral:24b-small-2506-q8_0" # Efficient reasoning + tools + thinking (25GB, higher precision)
      "gpt-oss:latest"     # OpenAI reasoning + tools + thinking (already downloaded)
      "qwen3:8b"           # Fallback lightweight option (already downloaded)
    ];
  };
}
