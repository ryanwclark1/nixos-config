{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  claudeHome = "${config.home.homeDirectory}/.claude";
  skillsDir = "${config.home.homeDirectory}/.local/share/agent-desk/skills";
  agentDeskContext = builtins.readFile ../shared/agent-desk-context.md;
  mcpConfig = import ../shared/mcp-config.nix { inherit config pkgs lib; };
  mcpServersNix = import inputs.mcp-servers-nix { inherit pkgs; };
  claudeMcpConfig = mcpServersNix.lib.mkConfig pkgs (
    mcpConfig
    // {
      flavor = "claude-code";
      format = "json";
      fileName = "mcp-servers.json";
    }
  );
  hookScripts = [
    "hook-common.sh"
    "format-hook.sh"
    "security-hook.sh"
    "lint-hook.sh"
    "typecheck-hook.sh"
    "notification-hook.sh"
    "git-safety-hook.sh"
  ];
  referenceDocs = [
    "BUSINESS_SYMBOLS.md"
    "KNOWLEDGE.md"
    "PLANNING.md"
    "MODE_Business_Panel.md"
  ];
  enabledAgents = {
    ai-engineer = "ai-engineer.md";
    backend-architect = "backend-architect.md";
    business-panel = "business-panel-experts.md";
    code-reviewer = "code-reviewer.md";
    debugger = "debugger.md";
    deep-research-agent = "deep-research-agent.md";
    devops-architect = "devops-architect.md";
    docs-architect = "docs-architect.md";
    frontend-architect = "frontend-architect.md";
    learning-guide = "learning-guide.md";
    nix-systems-specialist = "nix-systems-specialist.md";
    performance-engineer = "performance-engineer.md";
    python-pro = "python-pro.md";
    refactoring-expert = "refactoring-expert.md";
    requirements-analyst = "requirements-analyst.md";
    security-engineer = "security-engineer.md";
    socratic-mentor = "socratic-mentor.md";
    system-architect = "system-architect.md";
    test-automator = "test-automator.md";
  };
  hookFiles = builtins.listToAttrs (
    map (script: {
      name = "${claudeHome}/${script}";
      value = {
        source = ./. + "/${script}";
        executable = true;
      };
    }) hookScripts
  );
  referenceFiles = builtins.listToAttrs (
    map (doc: {
      name = "${claudeHome}/${doc}";
      value.source = ./config + "/${doc}";
    }) referenceDocs
  );
in
{
  home.file =
    hookFiles
    // referenceFiles
    // {
      "${claudeHome}/mcp-servers.json".source = claudeMcpConfig;
      "${claudeHome}/AGENT_DESK.md".text = agentDeskContext;
      "${claudeHome}/commands/sc/improve.md".text = ''
        ---
        name: improve
        description: Use the shared Agent Desk improve skill
        ---

        # /sc:improve

        Use the shared Agent Desk improve skill at:

        `${skillsDir}/improve/SKILL.md`

        Load and follow that skill as the canonical procedure for systematic code
        quality, performance, maintainability, style, and cleanup improvements.
      '';
    };

  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;
    enableMcpIntegration = true;
    context = ''
      ${agentDeskContext}

      ## Claude Code Role

      Claude Code is the senior implementation and refactoring agent.

      Default to:

      - Large-codebase reasoning
      - Scoped implementation
      - Refactoring
      - Documentation updates
      - Task-agent delegation for complex multi-step work

      Coordinate with Codex for validation and review, OpenCode for open/local
      workflows, and Antigravity for IDE-centric agent work.
    '';

    agents = lib.mapAttrs (_: file: builtins.readFile (./config/agents + "/${file}")) enabledAgents;
  };
}
