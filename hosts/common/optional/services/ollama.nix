{

  ...
}:

{
  services.ollama = {
    enable = true;
    port = 11434;
    host = "0.0.0.0";
    user = "ollama";
    group = "ollama";
    acceleration = "rocm";
    openFirewall = true;
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
