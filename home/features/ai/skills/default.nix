{
  config,
  pkgs,
  lib,
  ...
}:

let
  available = lib.filter (pkg: pkg != null);
  skillsDir = "${config.home.homeDirectory}/.local/share/agent-desk/skills";
in
{
  home.packages = available [
    (pkgs.skills or null)
    (pkgs.skills-installer or null)
    (pkgs.openskills or null)
    (pkgs.apm or null)
    (pkgs.context-hub or null)
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
}
