{
  config,
  pkgs,
  lib,
  ...
}:

let
  accentAiContext = builtins.readFile ../shared/accent-ai-context.md;
in

{
  programs.opencode = {
    enable = true;
    package = pkgs.opencode;
    enableMcpIntegration = true;
    context = ''
      ${accentAiContext}

      ## OpenCode Role

      OpenCode is the open-source and local-model-friendly execution agent.

      Default to:

      - Vendor-flexible implementation
      - Ollama/local-model workflows
      - Experimental agent workflows
      - Supplemental research and implementation
    '';
    agents = {
      research = ''
        Use the Research role from the Accent AI context. Gather constraints,
        options, and risks before proposing implementation.
      '';
      implementer = ''
        Use the Implementer role from the Accent AI context. Make scoped,
        testable changes tied to a Beads item or Gastown workflow stage.
      '';
      reviewer = ''
        Use the Reviewer role from the Accent AI context. Prioritize bugs,
        regressions, missing tests, and maintainability risks.
      '';
    };
    tui = {
      theme = "catppuccin";
    };
    settings = {
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
