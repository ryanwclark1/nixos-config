{
  config,
  pkgs,
  lib,
  ...
}:

let
  llmAgents = import ../shared/llm-agents-packages.nix { inherit pkgs lib; };
  skillsDir = "${config.home.homeDirectory}/.local/share/agent-desk/skills";
in
{
  home.packages = llmAgents.available [
    (llmAgents.from "skills" (pkgs.skills or null))
    (llmAgents.from "skills-installer" (pkgs.skills-installer or null))
    (llmAgents.from "openskills" (pkgs.openskills or null))
    (llmAgents.from "apm" (pkgs.apm or null))
    (llmAgents.from "context-hub" (pkgs.context-hub or null))
  ];

  home.sessionVariables = {
    AGENT_DESK_SKILLS_DIR = skillsDir;
  };

  home.file.".local/share/agent-desk/skills/README.md".text = ''
    # Agent Desk Shared Skills

    This directory is the shared skill library for Claude Code, Codex, OpenCode,
    Gastown workflows, and future agents.

    Suggested skill layout:

    - analyze-code
    - review-pr
    - create-migration
    - security-review
    - api-design
    - write-tests

    Prefer portable `SKILL.md` skills so multiple agents can load the same
    procedure instead of maintaining separate prompt libraries.
  '';

  home.file.".local/share/agent-desk/skills/improve/SKILL.md".source = ./improve/SKILL.md;
}
