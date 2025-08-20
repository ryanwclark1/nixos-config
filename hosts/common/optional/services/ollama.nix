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
      "deepseek-r1:8b"
      "qwen3-coder:30b"
      "gpt-oss:latest"
    ];
  };
}
