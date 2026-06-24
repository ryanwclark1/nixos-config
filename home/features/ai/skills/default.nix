{
  config,
  pkgs,
  lib,
  ...
}:

let
  available = lib.filter (pkg: pkg != null);
  skillsDir = "${config.home.homeDirectory}/.local/share/accent-ai/skills";
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
    ACCENT_AI_SKILLS_DIR = skillsDir;
  };

  home.file.".local/share/accent-ai/skills/README.md".text = ''
    # Accent AI Shared Skills

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
