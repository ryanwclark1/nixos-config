{
  config,
  pkgs,
  lib,
  ...
}:

let
  qwenHome = "${config.home.homeDirectory}/.qwen";
  settingsPath = "${qwenHome}/settings.json";

  # Import MCP servers configuration
  mcpServersRaw = builtins.fromJSON (builtins.readFile ./mcp-servers.json);
  mcpServers = mcpServersRaw;
in
{
  home.file."${qwenHome}/AGENTS.md" = {
    source = ./config/AGENTS.md;
  };
  home.file."${qwenHome}/FLAGS.md" = {
    source = ./config/FLAGS.md;
  };
  home.file."${qwenHome}/PRINCIPLES.md" = {
    source = ./config/PRINCIPLES.md;
  };
  home.file."${qwenHome}/RULES.md" = {
    source = ./config/RULES.md;
  };

  # MODES
  home.file."${qwenHome}/MODE_Brainstorming.md" = {
    source = ./config/MODE_Brainstorming.md;
  };
  home.file."${qwenHome}/MODE_Introspection.md" = {
    source = ./config/MODE_Introspection.md;
  };
  home.file."${qwenHome}/MODE_Orchestration.md" = {
    source = ./config/MODE_Orchestration.md;
  };
  home.file."${qwenHome}/MODE_Task_Management.md" = {
    source = ./config/MODE_Task_Management.md;
  };
  home.file."${qwenHome}/MODE_Token_Efficiency.md" = {
    source = ./config/MODE_Token_Efficiency.md;
  };

  # MCP SERVERS
  home.file."${qwenHome}/MCP_Context7.md" = {
    source = ./config/MCP_Context7.md;
  };
  home.file."${qwenHome}/MCP_Playwright.md" = {
    source = ./config/MCP_Playwright.md;
  };
  home.file."${qwenHome}/MCP_Sequential.md" = {
    source = ./config/MCP_Sequential.md;
  };
  home.file."${qwenHome}/MCP_Serena.md" = {
    source = ./config/MCP_Serena.md;
  };

  # AGENTS
  home.file."${qwenHome}/agents/backend-architect.md" = {
    source = ./config/agents/backend-architect.md;
  };
  home.file."${qwenHome}/agents/devops-architect.md" = {
    source = ./config/agents/devops-architect.md;
  };
  home.file."${qwenHome}/agents/frontend-architect.md" = {
    source = ./config/agents/frontend-architect.md;
  };
  home.file."${qwenHome}/agents/learning-guide.md" = {
    source = ./config/agents/learning-guide.md;
  };
  home.file."${qwenHome}/agents/performance-engineer.md" = {
    source = ./config/agents/performance-engineer.md;
  };
  home.file."${qwenHome}/agents/python-expert.md" = {
    source = ./config/agents/python-expert.md;
  };
  home.file."${qwenHome}/agents/quality-engineer.md" = {
    source = ./config/agents/quality-engineer.md;
  };
  home.file."${qwenHome}/agents/refactoring-expert.md" = {
    source = ./config/agents/refactoring-expert.md;
  };
  home.file."${qwenHome}/agents/requirements-analyst.md" = {
    source = ./config/agents/requirements-analyst.md;
  };
  home.file."${qwenHome}/agents/root-cause-analyst.md" = {
    source = ./config/agents/root-cause-analyst.md;
  };
  home.file."${qwenHome}/agents/security-engineer.md" = {
    source = ./config/agents/security-engineer.md;
  };
  home.file."${qwenHome}/agents/system-architect.md" = {
    source = ./config/agents/system-architect.md;
  };
  home.file."${qwenHome}/agents/technical-writer.md" = {
    source = ./config/agents/technical-writer.md;
  };

  # COMMANDS
  home.file."${qwenHome}/commands/sq/analyze.md" = {
    source = ./config/commands/sq/analyze.md;
  };
  home.file."${qwenHome}/commands/sq/build.md" = {
    source = ./config/commands/sq/build.md;
  };
  home.file."${qwenHome}/commands/sq/cleanup.md" = {
    source = ./config/commands/sq/cleanup.md;
  };
  home.file."${qwenHome}/commands/sq/design.md" = {
    source = ./config/commands/sq/design.md;
  };
  home.file."${qwenHome}/commands/sq/document.md" = {
    source = ./config/commands/sq/document.md;
  };
  home.file."${qwenHome}/commands/sq/estimate.md" = {
    source = ./config/commands/sq/estimate.md;
  };
  home.file."${qwenHome}/commands/sq/explain.md" = {
    source = ./config/commands/sq/explain.md;
  };
  home.file."${qwenHome}/commands/sq/git.md" = {
    source = ./config/commands/sq/git.md;
  };
  home.file."${qwenHome}/commands/sq/help.md" = {
    source = ./config/commands/sq/help.md;
  };
  home.file."${qwenHome}/commands/sq/implement.md" = {
    source = ./config/commands/sq/implement.md;
  };
  home.file."${qwenHome}/commands/sq/improve.md" = {
    source = ./config/commands/sq/improve.md;
  };
  home.file."${qwenHome}/commands/sq/index.md" = {
    source = ./config/commands/sq/index.md;
  };
  home.file."${qwenHome}/commands/sq/load.md" = {
    source = ./config/commands/sq/load.md;
  };
  home.file."${qwenHome}/commands/sq/reflect.md" = {
    source = ./config/commands/sq/reflect.md;
  };
  home.file."${qwenHome}/commands/sq/research.md" = {
    source = ./config/commands/sq/research.md;
  };
  home.file."${qwenHome}/commands/sq/save.md" = {
    source = ./config/commands/sq/save.md;
  };
  home.file."${qwenHome}/commands/sq/select-tool.md" = {
    source = ./config/commands/sq/select-tool.md;
  };
  home.file."${qwenHome}/commands/sq/spawn.md" = {
    source = ./config/commands/sq/spawn.md;
  };
  home.file."${qwenHome}/commands/sq/spec-panel.md" = {
    source = ./config/commands/sq/spec-panel.md;
  };
  home.file."${qwenHome}/commands/sq/task.md" = {
    source = ./config/commands/sq/task.md;
  };
  home.file."${qwenHome}/commands/sq/test.md" = {
    source = ./config/commands/sq/test.md;
  };
  home.file."${qwenHome}/commands/sq/troubleshoot.md" = {
    source = ./config/commands/sq/troubleshoot.md;
  };
  home.file."${qwenHome}/commands/sq/workflow.md" = {
    source = ./config/commands/sq/workflow.md;
  };

  home.packages = with pkgs; [
    qwen-code
  ];

  # Create Qwen Code settings.json configuration
  home.file.".qwen/settings.json" = {
    force = true;  # Always overwrite, avoiding conflicts
    text = builtins.toJSON {
    # UI Settings
    theme = "dark";
    customThemes = {
      dark = {
        name = "Dark";
        colors = {
          background = "#1e1e1e";
          foreground = "#d4d4d4";
          primary = "#007acc";
          secondary = "#3e3e42";
          accent = "#007acc";
          error = "#f48771";
          warning = "#cca700";
          info = "#75beff";
          success = "#89d185";
        };
      };
    };
    hideWindowTitle = false;
    hideTips = false;
    hideBanner = false;
    hideFooter = false;
    showMemoryUsage = true;
    enableWelcomeBack = true;

    # General Settings
    usageStatisticsEnabled = true;
    autoConfigureMaxOldSpaceSize = true;
    preferredEditor = "nvim";
    maxSessionTurns = -1; # unlimited
    memoryImportFormat = "tree";
    memoryDiscoveryMaxDirs = 200;
    contextFileName = [ "QWEN.md" "README.md" "CLAUDE.md" "GEMINI.md" "CODEX.md" "CONTEXT.md" ];
    model = "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q4_K_XL";
    hasSeenIdeIntegrationNudge = false;
    folderTrustFeature = false;
    folderTrust = false;
    showLineNumbers = true;
    enableOpenAILogging = false;
    skipNextSpeakerCheck = false;
    includeDirectories = [];
    loadMemoryFromIncludeDirectories = false;
    excludedProjectEnvVars = [ "DEBUG" "DEBUG_MODE" ];

    # Mode Settings
    vimMode = false;
    ideMode = false;

    # Accessibility Settings
    accessibility = {
      disableLoadingPhrases = false;
    };

    # Checkpointing Settings
    checkpointing = {
      enabled = false;
    };

    # File Filtering Settings
    fileFiltering = {
      respectGitIgnore = true;
      respectGeminiIgnore = true;
      enableRecursiveFileSearch = true;
    };

    # Updates Settings
    disableAutoUpdate = false;
    disableUpdateNag = false;

    # Shell Settings
    shouldUseNodePtyShell = false;

    # Authentication Settings (using local Ollama)
    selectedAuthType = "api_key";
    useExternalAuth = false;

    # Advanced Settings
    sandbox = false;
    coreTools = [];
    excludeTools = [];
    toolDiscoveryCommand = null;
    toolCallCommand = null;
    mcpServerCommand = null;

    # MCP Servers Configuration (imported from mcp-servers.json)
    inherit mcpServers;

    allowMCPServers = null;
    excludeMCPServers = null;
    telemetry = null;
    bugCommand = null;
    summarizeToolOutput = null;
    dnsResolutionOrder = "ipv4first";

    # Chat Compression Settings
    chatCompression = {
      enabled = false;
      maxTokens = 8192;
    };

    # Content Generator Settings
    contentGenerator = {
      timeout = 30000; # 30 seconds
      maxRetries = 3;
      disableCacheControl = false;
    };

    # Session Settings
    sessionTokenLimit = 128000; # Qwen3 Coder context window

    # System Prompt Mappings (for Qwen models)
    systemPromptMappings = {
      "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q4_K_XL" = "You are Qwen, a coding assistant created by Alibaba Cloud.";
    };

    # Tavily API (optional, for web search)
    tavilyApiKey = null;
    };
  };

    # Create .env file with secrets from SOPS
  # Create a script that generates the .env file at runtime
  home.file."${qwenHome}/.env" = {
    force = true;
    text = ''
      # MCP Server Environment Variables
      # This file is generated at runtime by the .env-generator script
      CONTEXT7_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.context7-token.path})
      GITHUB_PERSONAL_ACCESS_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.github-pat.path})
      SOURCEBOT_API_KEY=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."sourcebot/api-key".path})
    '';
  };

  # Create a systemd user service to generate .env file after SOPS secrets are available
  systemd.user.services.generate-qwen-env = {
    Unit = {
      Description = "Generate Qwen .env file with SOPS secrets";
      After = [ "sops-nix.service" ];
      Wants = [ "sops-nix.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "generate-qwen-env" ''
        #!/bin/bash
        # Generate .env file with actual secret values at runtime

        # Check if secrets exist
        if [ ! -f "${config.sops.secrets.context7-token.path}" ] || \
           [ ! -f "${config.sops.secrets.github-pat.path}" ] || \
           [ ! -f "${config.sops.secrets."sourcebot/api-key".path}" ]; then
          echo "Warning: Some SOPS secrets are not available yet" >&2
          exit 1
        fi

        # Generate the .env file with actual values
        cat > "${qwenHome}/.env" << EOF
        # MCP Server Environment Variables
        CONTEXT7_TOKEN=$(cat "${config.sops.secrets.context7-token.path}")
        GITHUB_PERSONAL_ACCESS_TOKEN=$(cat "${config.sops.secrets.github-pat.path}")
        SOURCEBOT_API_KEY=$(cat "${config.sops.secrets."sourcebot/api-key".path}")
        EOF

        chmod 600 "${qwenHome}/.env"
        echo "Generated .env file with actual secret values"
      '';
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
