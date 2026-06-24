{ pkgs, lib, ... }:

let
  llmAgents = import ../shared/llm-agents-packages.nix { inherit pkgs lib; };
in
{
  home.packages = llmAgents.available [
    (llmAgents.from "cli-proxy-api" (pkgs.cli-proxy-api or null))
    (llmAgents.from "mcporter" (pkgs.mcporter or null))
    (llmAgents.from "claude-code-router" (pkgs.claude-code-router or null))
    (llmAgents.from "rtk" (pkgs.rtk or null))
  ];

  xdg.configFile."agent-desk/architecture/model-proxy.md".text = ''
    # Model Abstraction Layer

    The workstation should be ready for an OpenAI-compatible proxy layer.

    Goal:

    Agents -> Compatibility Layer -> Claude / GPT / Gemini / Local Models

    This keeps Gastown and other orchestration tools from needing provider-
    specific SDK wiring for every agent role.
  '';
}
