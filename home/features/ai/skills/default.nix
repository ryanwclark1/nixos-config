{
  config,
  pkgs,
  lib,
  ...
}:

let
  skillsDir = "${config.home.homeDirectory}/.local/share/agent-desk/skills";
in
{
  home.packages = lib.filter (p: p != null) [
    pkgs.skills
    pkgs.skills-installer
    pkgs.openskills
    pkgs.apm
    pkgs.context-hub
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
