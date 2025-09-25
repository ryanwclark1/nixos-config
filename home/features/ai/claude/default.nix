{
  config,
  pkgs,
  lib,
  ...
}:

let
  claudeHome = "${config.home.homeDirectory}/.claude";
  settingsPath = "${claudeHome}/settings.json";
in
{
  home.file = {
    ".claude/statusline.sh" = {
      source = ./config/statusline.sh;
      executable = true;
    };
    ".claude/BUSINESS_SYMBOLS.md" = {
      source = ./config/BUSINESS_SYMBOLS.md;
    };
    ".claude/FLAGS.md" = {
      source = ./config/FLAGS.md;
    };
    ".claude/PRINCIPLES.md" = {
      source = ./config/PRINCIPLES.md;
    };
    ".claude/RESEARCH_CONFIG.md" = {
      source = ./config/RESEARCH_CONFIG.md;
    };
    ".claude/RULES.md" = {
      source = ./config/RULES.md;
    };
    ".claude/MODE_Brainstorming.md" = {
      source = ./config/MODE_Brainstorming.md;
    };
    ".claude/MODE_Business_Panel.md" = {
      source = ./config/MODE_Business_Panel.md;
    };
    ".claude/MODE_DeepResearch.md" = {
      source = ./config/MODE_DeepResearch.md;
    };
    ".claude/MODE_Introspection.md" = {
      source = ./config/MODE_Introspection.md;
    };
    ".claude/MODE_Orchestration.md" = {
      source = ./config/MODE_Orchestration.md;
    };
    ".claude/MODE_Task_Management.md" = {
      source = ./config/MODE_Task_Management.md;
    };
    ".claude/MODE_Token_Efficiency.md" = {
      source = ./config/MODE_Token_Efficiency.md;
    };
    ".claude/MCP_Contex7.md" = {
      source = ./config/MCP_Contex7.md;
    };
    ".claude/MCP_Playwright.md" = {
      source = ./config/MCP_Playwright.md;
    };
    ".claude/MCP_Sequential.md" = {
      source = ./config/MCP_Sequential.md;
    };
    ".claude/MCP_Serena.md" = {
      source = ./config/MCP_Serena.md;
    };
  };

  programs.claude-code = {
    enable  = true;
    package = pkgs.claude-code;

    settings = {
      env = {
        DISABLE_TELEMETRY = "1";
        USE_BUILTIN_RIPGREP = "0"; # prefer system rg
      };

      # Permissions (deny sensitive files; allow/ask examples)
      permissions = {
        allow = [
          "*"
        ];
      };

      # Hooks: run before/after tool use (example)
      hooks = {
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              { type = "command"; command = "echo 'Running tool…' >&2"; }
            ];
          }
        ];
        PostToolUse = [
          {
            matcher = "Bash";
            hooks = [
              { type = "command"; command = "echo 'Tool done.' >&2"; }
            ];
          }
        ];
      };

      outputStyle = "Explanatory";
      model = "sonnet";

      statusLine = {
        type = "command";
        command = "${claudeHome}/statusline.sh";
        padding = 0; # Optional: set to 0 to let status line go to
      };
      forceLoginMethod = "console";

      # Example memory settings (user-level)
      memory = {
        enabled = true;
        dir = "{{HOME}}/.local/share/claude-code/memory";
        scope = "per-project";
        maxItems = 200;
      };

    };

    mcpServers = builtins.fromJSON (builtins.readFile ./mcp-servers.json);

    # Import agents from the agents/ directory
    agents = {
      # ai-engineer = (builtins.readFile ./config/agents/ai-engineer.md);
      # architect-review = (builtins.readFile ./config/agents/architect-review.md);
      # code-reviewer = (builtins.readFile ./config/agents/code-reviewer.md);
      # debugger = (builtins.readFile ./config/agents/debugger.md);
      # docs-architect = (builtins.readFile ./config/agents/docs-architect.md);
      # error-detective = (builtins.readFile ./config/agents/error-detective.md);
      # mermaid-expert = (builtins.readFile ./config/agents/mermaid-expert.md);
      # nix-systems-specialist = (builtins.readFile ./config/agents/nix-systems-specialist.md);
      # rust-pro = (builtins.readFile ./config/agents/rust-pro.md);
      # sql-pro = (builtins.readFile ./config/agents/sql-pro.md);
      # test-automator = (builtins.readFile ./config/agents/test-automator.md);
      # typescript-pro = (builtins.readFile ./config/agents/typescript-pro.md);
      backend-architect = (builtins.readFile ./config/agents/backend-architect.md);
      business-panel = (builtins.readFile ./config/agents/business-panel.md);
      deep-research-agent = (builtins.readFile ./config/agents/deep-research-agent.md);
      devops-architect = (builtins.readFile ./config/agents/devops-architect.md);
      frontend-architect = (builtins.readFile ./config/agents/frontend-architect.md);
      learning-guide = (builtins.readFile ./config/agents/learning-guide.md);
      performance-engineer = (builtins.readFile ./config/agents/performance-engineer.md);
      python-expert = (builtins.readFile ./config/agents/python-expert.md);
      quality-engineer = (builtins.readFile ./config/agents/quality-engineer.md);
      python-pro = (builtins.readFile ./config/agents/python-pro.md);
      refactoring-expert = (builtins.readFile ./config/agents/refactoring-expert.md);
      requirements-analyst = (builtins.readFile ./config/agents/requirements-analyst.md);
      root-cause-analyst = (builtins.readFile ./config/agents/root-cause-analyst.md);
      security-engineer = (builtins.readFile ./config/agents/security-engineer.md);
      socratic-mentor = (builtins.readFile ./config/agents/socratic-mentor.md);
      system-architect = (builtins.readFile ./config/agents/system-architect.md);
      technical-writer = (builtins.readFile ./config/agents/technical-writer.md);
    };

    # commandsDir = "./sc/commands";

    commands = {
      analyze = (builtins.readFile ./config/commands/sc/analyze.md);
      brainstorm = (builtins.readFile ./config/commands/sc/brainstorm.md);
      build = (builtins.readFile ./config/commands/sc/build);
      business-panel = (builtins.readFile ./config/commands/sc/business-panel.md);
      cleanup = (builtins.readFile ./config/commands/sc/cleanup.md);
      document = (builtins.readFile ./config/commands/sc/document.md);
      estimate = (builtins.readFile ./config/commands/sc/estimage.md);
      explain = (builtins.readFile ./config/commands/sc/explain.md);
      git = (builtins.readFile ./config/commands/sc/git.md);
      help = (builtins.readFile ./config/commands/sc/help.md);
      implement = (builtins.readFile ./config/commands/sc/implement.md);
      improvement = (builtins.readFile ./config/commands/sc/improvement.md);
      index = (builtins.readFile ./config/commands/sc/index.md);
      load = (builtins.readFile ./config/commands/sc/load.md);
      reflect = (builtins.readFile ./config/commands/sc/reflect.md);
      research = (builtins.readFile ./config/commands/sc/research.md);
      save = (builtins.readFile ./config/commands/sc/save.md);
      select-tool = (builtins.readFile ./config/commands/sc/select-tool.md);
      spawn = (builtins.readFile ./config/commands/sc/spawn.md);
      spec-panel = (builtins.readFile ./config/commands/sc/spec-panel.md);
      task = (builtins.readFile ./config/commands/sc/task.md);
      test = (builtins.readFile ./config/commands/sc/test.md);
      troubleshoot = (builtins.readFile ./config/commands/sc/troubleshoot.md);
      workflow = (builtins.readFile ./config/commands/sc/workflow.md);
    };
  };

  # Create .env file with secrets from SOPS
  home.file."${claudeHome}/.env" = {
    force = true;
    text = ''
      # MCP Server Environment Variables
      CONTEXT7_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.context7-token.path})
      GITHUB_PERSONAL_ACCESS_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.github-pat.path})
      SOURCEBOT_API_KEY=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."sourcebot/api-key".path})
    '';
    onChange = ''
      # Expand SOPS secrets in .env file
      if [ -f "${claudeHome}/.env" ]; then
        tmp=$(${pkgs.coreutils}/bin/mktemp)

        # Process each line to expand shell commands
        while IFS= read -r line || [[ -n "$line" ]]; do
          # Skip empty lines and comments
          if [[ -z "$line" ]] || [[ "$line" =~ ^# ]]; then
            echo "$line" >> "$tmp"
            continue
          fi

          # Handle lines with command substitution
          if [[ "$line" == *'=$('* ]] && [[ "$line" == *')'* ]]; then
            # Extract variable name and command
            var_name="''${line%%=*}"
            cmd_part="''${line#*=}"

            # Remove $( and ) from command using string manipulation
            if [[ "$cmd_part" == \$\(* ]] && [[ "$cmd_part" == *\) ]]; then
              cmd="''${cmd_part#\$\(}"   # Remove $( from start
              cmd="''${cmd%\)}"          # Remove ) from end

              # Execute the command and capture the result
              if value=$(eval "$cmd" 2>/dev/null); then
                echo "$var_name=$value" >> "$tmp"
              else
                # If command fails, keep original line
                echo "$line" >> "$tmp"
              fi
            else
              echo "$line" >> "$tmp"
            fi
          else
            # Line doesn't contain command substitution, keep as-is
            echo "$line" >> "$tmp"
          fi
        done < "${claudeHome}/.env"

        # Replace the original file
        ${pkgs.coreutils}/bin/mv "$tmp" "${claudeHome}/.env"
        ${pkgs.coreutils}/bin/chmod 600 "${claudeHome}/.env"
      fi
    '';
  };
}
