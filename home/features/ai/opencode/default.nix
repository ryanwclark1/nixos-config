{
  config,
  pkgs,
  lib,
  ...
}:


{
  programs.opencode = {
    enable = true;
    package = pkgs.opencode;
    settings = {
      theme = "catppuccin";
      provider = {
        ollama = {
          npm = "@ai-sdk/openai-compatible";
          name = "Ollama (local)";
          options = {
            baseURL = "http://localhost:11434/v1";
          };
          models = {
            "devstral-small-2" = {
              name = "devstral-small-2";
            };
            "qwen3-coder" = {
              name = "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Q4_K_M";
            };
          };
        };
      };
    };
  };
}
