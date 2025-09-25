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
      source = ./statusline.sh;
      executable = true;
    };
    ".claude/FLAGS.md" = {
      source = ./FLAGS.md;
    };
    ".claude/PRINCIPLES.md" = {
      source = ./PRINCIPLES.md
    }
    ".claude/RESEARCH_CONFIG.md" = {
      source = ./RESEARCH_CONFIG.md
    }
    ".claude/RULES.md" = {
      source = ./RULES.md
    }
    ".claude/MODE_Brainstorming.md" = {
      source = ./MODE_Brainstorming.md
    }
    ".claude/MODE_Business_Panel.md" = {
      source = ./MODE_Business_Panel.md
    }
    ".claude/MODE_DeepResearch.md = {
      source = ./MODE_DeepResearch.md
    }



    {
      ".claude/MCP_Contex7.md = {
        source = ./MCP_Contex7.md
      }
    }


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
      ai-engineer = (builtins.readFile ./agents/ai-engineer.md);
      architect-review = (builtins.readFile ./agents/architect-review.md);
      backend-architect = (builtins.readFile ./agents/backend-architect.md);
      code-reviewer = (builtins.readFile ./agents/code-reviewer.md);
      debugger = (builtins.readFile ./agents/debugger.md);
      docs-architect = (builtins.readFile ./agents/docs-architect.md);
      error-detective = (builtins.readFile ./agents/error-detective.md);
      mermaid-expert = (builtins.readFile ./agents/mermaid-expert.md);
      nix-systems-specialist = (builtins.readFile ./agents/nix-systems-specialist.md);
      python-pro = (builtins.readFile ./agents/python-pro.md);
      refactoring-expert = (builtins.readFile ./agents/refactoring-expert.md);
      requirements-analyst = (builtins.readFile ./agents/requirements-analyst.md);
      root-cause-analyst = (builtins.readFile ./agents/root-cause-analyst.md);
      rust-pro = (builtins.readFile ./agents/rust-pro.md);
      socratic-mentor = (builtins.readFile ./agents/socratic-mentor.md);
      sql-pro = (builtins.readFile ./agents/sql-pro.md);
      test-automator = (builtins.readFile ./agents/test-automator.md);
      typescript-pro = (builtins.readFile ./agents/typescript-pro.md);
    };

    commandsDir = ./sc/commands

    commands = {
      analyze = (builtins.readFile ./commands/sc/analyze.md);
      brainstorm = (builtins.readFile ./commands/sc/brainstorm.md)
      build = (builtins.readFile ./commands/sc/build)
      business-panel = (builtins.readFile ./commands/sc/business-panel.md)
      cleanup = (builtins.readFile ./commands/sc/cleanup.md);
      document = (builtins.readFile ./commands/sc/document.md);
      estimate = (builtins.readFile ./commands/sc/estimage.md);
      explain = (builtins.readFile ./commands/sc/explain.md);
      git = (builtins.readFile ./commands/sc/git.md);
      help = (builtins.readFile ./commands/sc/help.md);
      implement = (builtins.readFile ./commands/sc/implement.md);
      improvement = (builtins.readFile ./commands/sc/improvement.md);
      index = (builtins.readFile ./commands/sc/index.md);
      load = (builtins.readFile ./commands/sc/load.md);
      reflect = (builtins.readFile ./commands/sc/reflect.md);
      research = (builtins.readFile ./commands/sc/research.md);
      save = (builtins.readFile ./commands/sc/save.md);
      select-tool = (builtins.readFile ./commands/sc/select-tool.md);
      spawn = (builtins.readFile ./commands/sc/spawn.md);
      spec-panel = (builtins.readFile ./commands/sc/spec-panel.md);
      task = (builtins.readFile ./commands/sc/task.md);
      test = (builtins.readFile ./commands/sc/test.md);
      troubleshoot = (builtins.readFile ./commands/sc/troubleshoot.md);
      workflow = (builtins.readFile ./commands/sc/workflow.md);
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
