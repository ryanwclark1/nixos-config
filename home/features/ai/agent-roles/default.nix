{ pkgs, lib, ... }:

let
  available = lib.filter (pkg: pkg != null);
in
{
  home.packages = available [
    (pkgs.amp-cli or null)
    (pkgs.gemini-cli or null)
    (pkgs.goose-cli or null)
    (pkgs.qwen-code or null)
    (pkgs.crush or null)
    (pkgs.codex-acp or null)
    (pkgs.claude-agent-acp or null)
    (pkgs.codex-auth or null)
  ];

  xdg.configFile."accent-ai/agent-roles.md".text = ''
    # Accent AI Agent Roles

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
  '';
}
