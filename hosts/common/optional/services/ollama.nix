{
  lib,
  pkgs,
  ...
}:

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
    user = "ollama";
    group = "ollama";
    package = pkgs.ollama-rocm; # AMD GPU acceleration (replaces deprecated acceleration option)
    openFirewall = true;
    environmentVariables = {
      # Force Ollama to use only the discrete GPU (device 0 = RX 7800 XT)
      # Without this, ROCm may try to use the Ryzen 9950X iGPU (gfx1036)
      # which doesn't support the HIP kernels compiled for gfx1101
      HIP_VISIBLE_DEVICES = "0";
      ROCR_VISIBLE_DEVICES = "0";
      HSA_OVERRIDE_GFX_VERSION = "11.0.1"; # Match gfx1101 target
      LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.libdrm ];
    };
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
