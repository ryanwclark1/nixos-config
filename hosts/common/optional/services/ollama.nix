{

  ...
}:

{
  services.ollama = {
    enable = true;
    port = 11434;
    host = "127.0.0.1";
    user = "ollama";
    group = "ollama";
    acceleration = "rocm";
    openFirewall = true;
    loadModels = [
      "deepseek-r1:8b-0528-qwen3-q8_0"
      "qwen3-coder:30b"
    ];
  };
}
