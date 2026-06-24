{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  claudeHome = "${config.home.homeDirectory}/.claude";
  agentDeskContext = builtins.readFile ../shared/agent-desk-context.md;
  llmAgents = import ../shared/llm-agents-packages.nix { inherit pkgs lib; };
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

  home.file."${claudeHome}/mcp-servers.json".source = claudeMcpConfig;
  home.file."${claudeHome}/AGENT_DESK.md".text = agentDeskContext;

  # Project-specific Claude reference documentation.
  home.file."${claudeHome}/BUSINESS_SYMBOLS.md" = {
    source = ./config/BUSINESS_SYMBOLS.md;
  };
  home.file."${claudeHome}/KNOWLEDGE.md" = {
    source = ./config/KNOWLEDGE.md;
  };
  home.file."${claudeHome}/PLANNING.md" = {
    source = ./config/PLANNING.md;
  };
  home.file."${claudeHome}/MODE_Business_Panel.md" = {
    source = ./config/MODE_Business_Panel.md;
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
  home.file."${claudeHome}/commands/sc/research.md" = {
    source = ./config/commands/sc/research.md;
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
    package = llmAgents.from "claude-code" pkgs.claude-code;
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

    # Import agents from the agents/ directory
    agents = {
      ai-engineer = (builtins.readFile ./config/agents/ai-engineer.md);
      code-reviewer = (builtins.readFile ./config/agents/code-reviewer.md);
      debugger = (builtins.readFile ./config/agents/debugger.md);
      nix-systems-specialist = (builtins.readFile ./config/agents/nix-systems-specialist.md);
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
