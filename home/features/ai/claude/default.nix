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
  home.file."${claudeHome}/statusline.sh" = {
    source = ./statusline.sh;
    executable = true;
  };
  home.file."${claudeHome}/BUSINESS_SYMBOLS.md" = {
    source = ./config/BUSINESS_SYMBOLS.md;
  };
  home.file."${claudeHome}/FLAGS.md" = {
    source = ./config/FLAGS.md;
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
  home.file."${claudeHome}/commands/sc/cleanup.md" = {
    source = ./config/commands/sc/cleanup.md;
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
  home.file."${claudeHome}/commands/sc/select-tool.md" = {
    source = ./config/commands/sc/select-tool.md;
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
              {
                type = "command";
                command = "echo 'Running tool…' >&2";
              }
            ];
          }
        ];
        PostToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "echo 'Tool done.' >&2";
              }
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
        dir = "${config.home.homeDirectory}/.local/share/claude-code/memory";
        scope = "per-project";
        maxItems = 200;
      };

    };

    mcpServers = builtins.fromJSON (builtins.readFile ./mcp-servers.json);

    # Import agents from the agents/ directory
    agents = {
      # ai-engineer = (builtins.readFile ./config/agents/ai-engineer.md);
      # architect-review = (builtins.readFile ./config/agents/architect-review.md);
      code-reviewer = (builtins.readFile ./config/agents/code-reviewer.md);
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
      business-panel = (builtins.readFile ./config/agents/business-panel-experts.md);
      deep-research-agent = (builtins.readFile ./config/agents/deep-research-agent.md);
      devops-architect = (builtins.readFile ./config/agents/devops-architect.md);
      frontend-architect = (builtins.readFile ./config/agents/frontend-architect.md);
      learning-guide = (builtins.readFile ./config/agents/learning-guide.md);
      performance-engineer = (builtins.readFile ./config/agents/performance-engineer.md);
      python-expert = (builtins.readFile ./config/agents/python-expert.md);
      quality-engineer = (builtins.readFile ./config/agents/quality-engineer.md);
      refactoring-expert = (builtins.readFile ./config/agents/refactoring-expert.md);
      requirements-analyst = (builtins.readFile ./config/agents/requirements-analyst.md);
      root-cause-analyst = (builtins.readFile ./config/agents/root-cause-analyst.md);
      security-engineer = (builtins.readFile ./config/agents/security-engineer.md);
      socratic-mentor = (builtins.readFile ./config/agents/socratic-mentor.md);
      system-architect = (builtins.readFile ./config/agents/system-architect.md);
      technical-writer = (builtins.readFile ./config/agents/technical-writer.md);
    };

  };

  # Create .env file with secrets from SOPS
  # Create a script that generates the .env file at runtime
  home.file."${claudeHome}/.env" = {
    force = true;
    text = ''
      # Qwen Code Configuration with Local Ollama
      # This file is loaded by qwen-code automatically

      # OpenAI API compatible configuration for local Ollama
      OPENAI_API_BASE=http://localhost:11434/v1
      OPENAI_BASE_URL=http://localhost:11434/v1
      OPENAI_API_KEY=ollama

      # Model configuration
      OPENAI_MODEL=hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q4_K_XL
      MODEL=hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q4_K_XL

      # Qwen Code specific settings
      QWEN_MODEL=hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q4_K_XL
      QWEN_BASE_URL=http://localhost:11434/v1
      QWEN_API_KEY=ollama

      # MCP Integration for Qwen Code
      QWEN_MCP_CONFIG=${config.home.homeDirectory}/.config/open-webui/mcp-servers-processed.json
      MCP_CONFIG_FILE=${config.home.homeDirectory}/.config/open-webui/mcp-servers-processed.json
      MCP_TRANSPORT=stdio

      # Performance settings
      MAX_TOKENS=8192
      TEMPERATURE=0.1
      TOP_P=0.95

      # Ollama connection settings
      OLLAMA_HOST=localhost:11434
      OLLAMA_API_BASE=http://localhost:11434

      # Code generation preferences
      QWEN_CODE_STYLE=concise
      QWEN_EXPLAIN_LEVEL=brief

      # Debug settings (excluded from project .env by qwen-code)
      # DEBUG=false
      # DEBUG_MODE=false

      # MCP Server Environment Variables
      # This file is generated at runtime by the .env-generator script
      CONTEXT7_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.context7-token.path})
      GITHUB_PERSONAL_ACCESS_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.github-pat.path})
      SOURCEBOT_API_KEY=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."sourcebot/api-key".path})
    '';
  };

  # Create a systemd user service to generate .env file after SOPS secrets are available
  systemd.user.services.generate-claude-env = {
    Unit = {
      Description = "Generate Claude .env file with SOPS secrets";
      After = [ "sops-nix.service" ];
      Wants = [ "sops-nix.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "generate-claude-env" ''
        #!/usr/bin/env bash
        # Generate .env file with actual secret values at runtime

        # Check if secrets exist
        if [ ! -f "${config.sops.secrets.context7-token.path}" ] || \
           [ ! -f "${config.sops.secrets.github-pat.path}" ] || \
           [ ! -f "${config.sops.secrets."sourcebot/api-key".path}" ]; then
          echo "Warning: Some SOPS secrets are not available yet" >&2
          exit 1
        fi

        # Generate the .env file with actual values
        cat > "${claudeHome}/.env" << EOF
        # MCP Server Environment Variables
        CONTEXT7_TOKEN=$(cat "${config.sops.secrets.context7-token.path}")
        GITHUB_PERSONAL_ACCESS_TOKEN=$(cat "${config.sops.secrets.github-pat.path}")
        SOURCEBOT_API_KEY=$(cat "${config.sops.secrets."sourcebot/api-key".path}")
        EOF

        chmod 600 "${claudeHome}/.env"
        echo "Generated .env file with actual secret values"
      '';
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
