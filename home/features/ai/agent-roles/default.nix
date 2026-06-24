{ pkgs, lib, ... }:

{
  home.packages = lib.filter (p: p != null) [
    pkgs.antigravity-cli
    pkgs.jules
    pkgs.codex-acp
    pkgs.claude-agent-acp
    pkgs.codex-auth
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
    - Antigravity CLI (`agy`) for Google agent workflows from the terminal
    - OpenCode for open-source, local-model, and experimental workflows
    - Jules for asynchronous Google coding-agent workflows
  '';
}
