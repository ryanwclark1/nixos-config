{
  config,
  pkgs,
  lib,
  ...
}:

let
  claudeHome = "${config.home.homeDirectory}/.claude";
  settingsPath = "${claudeHome}/settings.json";
  accentAiContext = builtins.readFile ../shared/accent-ai-context.md;
  mcpServers = lib.mapAttrs (
    _: lib.filterAttrs (_: value: value != null && value != [ ] && value != { })
  ) config.programs.mcp.servers;
in
{
  # Status line script for Claude Code
  home.file."${claudeHome}/statusline.sh" = {
    source = ./statusline.sh;
    executable = true;
  };

  # Format hook script for Python and TypeScript
  home.file."${claudeHome}/format-hook.sh" = {
    source = ./format-hook.sh;
    executable = true;
  };

  # Security hook: Block dangerous commands and protect sensitive files
  home.file."${claudeHome}/security-hook.sh" = {
    source = ./security-hook.sh;
    executable = true;
  };

  # Linting hook: Run linters after code changes
  home.file."${claudeHome}/lint-hook.sh" = {
    source = ./lint-hook.sh;
    executable = true;
  };

  # Type checking hook: Run type checkers after code changes
  home.file."${claudeHome}/typecheck-hook.sh" = {
    source = ./typecheck-hook.sh;
    executable = true;
  };

  # Notification hook: Desktop notifications when Claude needs attention
  home.file."${claudeHome}/notification-hook.sh" = {
    source = ./notification-hook.sh;
    executable = true;
  };

  # Git safety hook: Prevent dangerous git operations
  home.file."${claudeHome}/git-safety-hook.sh" = {
    source = ./git-safety-hook.sh;
    executable = true;
  };

  # Configuration Documentation Files
  # These files are reference documentation for Claude Code workflows, modes, and MCP servers.
  # They are automatically loaded via Cursor rules (.cursor/rules/claude-*.mdc) and should
  # be referenced when relevant. See .cursor/rules/claude-config.mdc for usage guidelines.

  home.file."${claudeHome}/mcp-servers.json".text = builtins.toJSON mcpServers;
  home.file."${claudeHome}/ACCENT_AI.md".text = accentAiContext;

  # Core behavioral and project documentation
  home.file."${claudeHome}/BUSINESS_SYMBOLS.md" = {
    source = ./config/BUSINESS_SYMBOLS.md;
  };
  home.file."${claudeHome}/FLAGS.md" = {
    source = ./config/FLAGS.md;
  };
  home.file."${claudeHome}/KNOWLEDGE.md" = {
    source = ./config/KNOWLEDGE.md;
  };
  home.file."${claudeHome}/PLANNING.md" = {
    source = ./config/PLANNING.md;
  };
  home.file."${claudeHome}/PRINCIPLES.md" = {
    source = ./config/PRINCIPLES.md;
  };
  home.file."${claudeHome}/RESEARCH_CONFIG.md" = {
    source = ./config/RESEARCH_CONFIG.md;
  };
  home.file."${claudeHome}/RULES.md" = {
    source = ./config/RULES.md;
  };
  home.file."${claudeHome}/TASK.md" = {
    source = ./config/TASK.md;
  };

  # MODES
  home.file."${claudeHome}/MODE_Brainstorming.md" = {
    source = ./config/MODE_Brainstorming.md;
  };
  home.file."${claudeHome}/MODE_Business_Panel.md" = {
    source = ./config/MODE_Business_Panel.md;
  };
  home.file."${claudeHome}/MODE_DeepResearch.md" = {
    source = ./config/MODE_DeepResearch.md;
  };
  home.file."${claudeHome}/MODE_Introspection.md" = {
    source = ./config/MODE_Introspection.md;
  };
  home.file."${claudeHome}/MODE_Orchestration.md" = {
    source = ./config/MODE_Orchestration.md;
  };
  home.file."${claudeHome}/MODE_Task_Management.md" = {
    source = ./config/MODE_Task_Management.md;
  };
  home.file."${claudeHome}/MODE_Token_Efficiency.md" = {
    source = ./config/MODE_Token_Efficiency.md;
  };

  # MCP SERVERS
  home.file."${claudeHome}/MCP_SERVERS.md" = {
    source = ./config/MCP_SERVERS.md;
  };
  home.file."${claudeHome}/MCP_Context7.md" = {
    source = ./config/MCP_Context7.md;
  };
  home.file."${claudeHome}/MCP_Playwright.md" = {
    source = ./config/MCP_Playwright.md;
  };
  home.file."${claudeHome}/MCP_Sequential.md" = {
    source = ./config/MCP_Sequential.md;
  };
  home.file."${claudeHome}/MCP_Serena.md" = {
    source = ./config/MCP_Serena.md;
  };
  home.file."${claudeHome}/MCP_Context7_SETUP.md" = {
    source = ./config/MCP_Context7_SETUP.md;
  };

  # COMMANDS
  home.file."${claudeHome}/commands/sc/analyze.md" = {
    source = ./config/commands/sc/analyze.md;
  };
  home.file."${claudeHome}/commands/sc/brainstorm.md" = {
    source = ./config/commands/sc/brainstorm.md;
  };
  home.file."${claudeHome}/commands/sc/build.md" = {
    source = ./config/commands/sc/build.md;
  };
  home.file."${claudeHome}/commands/sc/business-panel.md" = {
    source = ./config/commands/sc/business-panel.md;
  };
  home.file."${claudeHome}/commands/sc/design.md" = {
    source = ./config/commands/sc/design.md;
  };
  home.file."${claudeHome}/commands/sc/document.md" = {
    source = ./config/commands/sc/document.md;
  };
  home.file."${claudeHome}/commands/sc/estimate.md" = {
    source = ./config/commands/sc/estimate.md;
  };
  home.file."${claudeHome}/commands/sc/explain.md" = {
    source = ./config/commands/sc/explain.md;
  };
  home.file."${claudeHome}/commands/sc/git.md" = {
    source = ./config/commands/sc/git.md;
  };
  home.file."${claudeHome}/commands/sc/help.md" = {
    source = ./config/commands/sc/help.md;
  };
  home.file."${claudeHome}/commands/sc/implement.md" = {
    source = ./config/commands/sc/implement.md;
  };
  home.file."${claudeHome}/commands/sc/improve.md" = {
    source = ./config/commands/sc/improve.md;
  };
  home.file."${claudeHome}/commands/sc/index.md" = {
    source = ./config/commands/sc/index.md;
  };
  home.file."${claudeHome}/commands/sc/load.md" = {
    source = ./config/commands/sc/load.md;
  };
  home.file."${claudeHome}/commands/sc/reflect.md" = {
    source = ./config/commands/sc/reflect.md;
  };
  home.file."${claudeHome}/commands/sc/research.md" = {
    source = ./config/commands/sc/research.md;
  };
  home.file."${claudeHome}/commands/sc/save.md" = {
    source = ./config/commands/sc/save.md;
  };
  home.file."${claudeHome}/commands/sc/spawn.md" = {
    source = ./config/commands/sc/spawn.md;
  };
  home.file."${claudeHome}/commands/sc/spec-panel.md" = {
    source = ./config/commands/sc/spec-panel.md;
  };
  home.file."${claudeHome}/commands/sc/task.md" = {
    source = ./config/commands/sc/task.md;
  };
  home.file."${claudeHome}/commands/sc/test.md" = {
    source = ./config/commands/sc/test.md;
  };
  home.file."${claudeHome}/commands/sc/troubleshoot.md" = {
    source = ./config/commands/sc/troubleshoot.md;
  };
  home.file."${claudeHome}/commands/sc/workflow.md" = {
    source = ./config/commands/sc/workflow.md;
  };

  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;
    context = ''
      ${accentAiContext}

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

    mcpServers = mcpServers;

    # Import agents from the agents/ directory
    agents = {
      ai-engineer = (builtins.readFile ./config/agents/ai-engineer.md);
      # architect-review = (builtins.readFile ./config/agents/architect-review.md);
      code-reviewer = (builtins.readFile ./config/agents/code-reviewer.md);
      debugger = (builtins.readFile ./config/agents/debugger.md);
      # docs-architect = (builtins.readFile ./config/agents/docs-architect.md);
      # mermaid-expert = (builtins.readFile ./config/agents/mermaid-expert.md);
      nix-systems-specialist = (builtins.readFile ./config/agents/nix-systems-specialist.md);
      # rust-pro = (builtins.readFile ./config/agents/rust-pro.md);
      # sql-pro = (builtins.readFile ./config/agents/sql-pro.md);
      # test-automator = (builtins.readFile ./config/agents/test-automator.md);
      # typescript-pro = (builtins.readFile ./config/agents/typescript-pro.md);
      backend-architect = (builtins.readFile ./config/agents/backend-architect.md);
      business-panel = (builtins.readFile ./config/agents/business-panel-experts.md);
      deep-research-agent = (builtins.readFile ./config/agents/deep-research-agent.md);
      devops-architect = (builtins.readFile ./config/agents/devops-architect.md);
      frontend-architect = (builtins.readFile ./config/agents/frontend-architect.md);
      learning-guide = (builtins.readFile ./config/agents/learning-guide.md);
      performance-engineer = (builtins.readFile ./config/agents/performance-engineer.md);
      python-pro = (builtins.readFile ./config/agents/python-pro.md);
      refactoring-expert = (builtins.readFile ./config/agents/refactoring-expert.md);
      requirements-analyst = (builtins.readFile ./config/agents/requirements-analyst.md);
      security-engineer = (builtins.readFile ./config/agents/security-engineer.md);
      socratic-mentor = (builtins.readFile ./config/agents/socratic-mentor.md);
      system-architect = (builtins.readFile ./config/agents/system-architect.md);
      test-automator = (builtins.readFile ./config/agents/test-automator.md);
      docs-architect = (builtins.readFile ./config/agents/docs-architect.md);
    };

  };
}
