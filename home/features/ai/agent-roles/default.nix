{ pkgs, lib, ... }:

let
  llmAgents = import ../shared/llm-agents-packages.nix { inherit pkgs lib; };
in
{
  home.packages = llmAgents.available [
    (llmAgents.from "jules" (pkgs.jules or null))
    (llmAgents.from "codex-acp" (pkgs.codex-acp or null))
    (llmAgents.from "claude-agent-acp" (pkgs.claude-agent-acp or null))
    (llmAgents.from "codex-auth" (pkgs.codex-auth or null))
  ];

  xdg.configFile."agent-desk/agent-roles.md".text = ''
    # Agent Desk Agent Roles

    Research:
    - Investigate options
    - Collect constraints
    - Produce concise findings

    Architect:
    - Turn research into design
    - Write ADRs
    - Define integration boundaries

    Implementer:
    - Make scoped code changes
    - Keep changes tied to a Beads item or Gastown stage

    Reviewer:
    - Check correctness, regressions, tests, and maintainability
    - Prefer concrete file and line references

    Documentation:
    - Update architecture notes, runbooks, and workflow docs

    Primary execution agents:
    - Claude Code for senior implementation and refactoring
    - Codex for validation, review, and alternate implementations
    - OpenCode for open-source, local-model, and experimental workflows
    - Jules for asynchronous Google coding-agent workflows
  '';
}
