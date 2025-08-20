# AI Chat Client
{
  lib,
  config,
  pkgs,
  ...
}:

{

  programs.aichat = {
    enable = true;
    settings = {
      model = "ollama:gpt-oss:latest";
      clients = [
        {
          type = "openai-compatible";
          name = "ollama";
          api_base = "http://localhost:11434/v1";
          models = [
            {
              name = "gpt-oss:latest";
              supports_function_calling = true;
              supports_vision = true;
            }
          ];
        }
      ];
    };
  };
}
