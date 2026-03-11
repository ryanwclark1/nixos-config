{
  pkgs,
  ...
}:
# Ollama service configured via home-manager for woody only
# ROCm acceleration enabled for AMD GPU support
# ROCm packages are configured in hosts/woody/performance.nix
# This module is only imported in home/woody.nix, ensuring it's not available on other hosts
#
# Troubleshooting ROCm/CUDA errors:
# - If you see "GGML_ASSERT(max_blocks_per_sm > 0) failed", Ollama is trying to use CUDA instead of ROCm
# - Verify ROCm detection: rocminfo
# - Verify GPU access: rocm-smi
# - Check Ollama is using ROCm variant: systemctl --user status ollama
# - After rebuilding, restart Ollama: systemctl --user restart ollama
{
  services.ollama = {
    enable = true;
    port = 11434;
    host = "0.0.0.0";
    package = pkgs.ollama-rocm; # AMD GPU acceleration (replaces deprecated acceleration option)
    # Note: loadModels is not available in home-manager's ollama module
    # Models should be loaded manually via: ollama pull <model-name>
    # Or configured via NixOS module in hosts/common/optional/services/ollama.nix
  };
}
