{
  config,
  pkgs,
  lib,
  ...
}:

let
  crushHome = "${config.home.homeDirectory}/crush";
  settingsPath = "${crushHome}/crush.json";
in
{
  home.packages = with pkgs; [
    crush
  ];

  home.file."${crushHome}/crush.json" = {
    force = true;
    text = ''
      {
        "$schema": "https://charm.land/crush.json",
        "providers": {
          "ollama": {
            "name": "Ollama",
            "base_url": "http://localhost:11434/v1/",
            "type": "openai",
            "models": [
              {
                "name": "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q4_K_XL",
                "id": "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q4_K_XL",
                "context_window": 256000,
                "default_max_tokens": 20000
              }
            ]
        },
      }
    '';
  };
}
