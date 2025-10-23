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
    force = true;
    source = ./config/AGENTS.md;
  };
  home.file."${qwenHome}/FLAGS.md" = {
    force = true;
    source = ./config/FLAGS.md;
  };
  home.file."${qwenHome}/PRINCIPLES.md" = {
    force = true;
    source = ./config/PRINCIPLES.md;
  };
  home.file."${qwenHome}/RULES.md" = {
    force = true;
    source = ./config/RULES.md;
  };

  # MODES
  home.file."${qwenHome}/MODE_Brainstorming.md" = {
    force = true;
    source = ./config/MODE_Brainstorming.md;
  };
  home.file."${qwenHome}/MODE_Introspection.md" = {
    force = true;
    source = ./config/MODE_Introspection.md;
  };
  home.file."${qwenHome}/MODE_Orchestration.md" = {
    force = true;
    source = ./config/MODE_Orchestration.md;
  };
  home.file."${qwenHome}/MODE_Task_Management.md" = {
    force = true;
    source = ./config/MODE_Task_Management.md;
  };
  home.file."${qwenHome}/MODE_Token_Efficiency.md" = {
    force = true;
    source = ./config/MODE_Token_Efficiency.md;
  };

  # MCP SERVERS
  home.file."${qwenHome}/MCP_Context7.md" = {
    force = true;
    source = ./config/MCP_Context7.md;
  };
  home.file."${qwenHome}/MCP_Playwright.md" = {
    force = true;
    source = ./config/MCP_Playwright.md;
  };
  home.file."${qwenHome}/MCP_Sequential.md" = {
    force = true;
    source = ./config/MCP_Sequential.md;
  };
  home.file."${qwenHome}/MCP_Serena.md" = {
    force = true;
    source = ./config/MCP_Serena.md;
  };

  # AGENTS
  home.file."${qwenHome}/agents/backend-architect.md" = {
    force = true;
    source = ./config/agents/backend-architect.md;
  };
  home.file."${qwenHome}/agents/devops-architect.md" = {
    force = true;
    source = ./config/agents/devops-architect.md;
  };
  home.file."${qwenHome}/agents/frontend-architect.md" = {
    force = true;
    source = ./config/agents/frontend-architect.md;
  };
  home.file."${qwenHome}/agents/learning-guide.md" = {
    force = true;
    source = ./config/agents/learning-guide.md;
  };
  home.file."${qwenHome}/agents/performance-engineer.md" = {
    force = true;
    source = ./config/agents/performance-engineer.md;
  };
  home.file."${qwenHome}/agents/python-expert.md" = {
    force = true;
    source = ./config/agents/python-expert.md;
  };
  home.file."${qwenHome}/agents/quality-engineer.md" = {
    force = true;
    source = ./config/agents/quality-engineer.md;
  };
  home.file."${qwenHome}/agents/refactoring-expert.md" = {
    force = true;
    source = ./config/agents/refactoring-expert.md;
  };
  home.file."${qwenHome}/agents/requirements-analyst.md" = {
    force = true;
    source = ./config/agents/requirements-analyst.md;
  };
  home.file."${qwenHome}/agents/root-cause-analyst.md" = {
    force = true;
    source = ./config/agents/root-cause-analyst.md;
  };
  home.file."${qwenHome}/agents/security-engineer.md" = {
    force = true;
    source = ./config/agents/security-engineer.md;
  };
  home.file."${qwenHome}/agents/system-architect.md" = {
    force = true;
    source = ./config/agents/system-architect.md;
  };
  home.file."${qwenHome}/agents/technical-writer.md" = {
    force = true;
    source = ./config/agents/technical-writer.md;
  };

  # COMMANDS
  home.file."${qwenHome}/commands/sq/analyze.toml" = {
    force = true;
    source = ./config/commands/sq/analyze.toml;
  };
  home.file."${qwenHome}/commands/sq/build.toml" = {
    force = true;
    source = ./config/commands/sq/build.toml;
  };
  home.file."${qwenHome}/commands/sq/cleanup.toml" = {
    force = true;
    source = ./config/commands/sq/cleanup.toml;
  };
  home.file."${qwenHome}/commands/sq/design.toml" = {
    force = true;
    source = ./config/commands/sq/design.toml;
  };
  home.file."${qwenHome}/commands/sq/document.toml" = {
    force = true;
    source = ./config/commands/sq/document.toml;
  };
  home.file."${qwenHome}/commands/sq/estimate.toml" = {
    force = true;
    source = ./config/commands/sq/estimate.toml;
  };
  home.file."${qwenHome}/commands/sq/explain.toml" = {
    force = true;
    source = ./config/commands/sq/explain.toml;
  };
  home.file."${qwenHome}/commands/sq/git.toml" = {
    force = true;
    source = ./config/commands/sq/git.toml;
  };
  home.file."${qwenHome}/commands/sq/implement.toml" = {
    force = true;
    source = ./config/commands/sq/implement.toml;
  };
  home.file."${qwenHome}/commands/sq/improve.toml" = {
    force = true;
    source = ./config/commands/sq/improve.toml;
  };
  home.file."${qwenHome}/commands/sq/index.toml" = {
    force = true;
    source = ./config/commands/sq/index.toml;
  };
  home.file."${qwenHome}/commands/sq/load.toml" = {
    force = true;
    source = ./config/commands/sq/load.toml;
  };
  home.file."${qwenHome}/commands/sq/reflect.toml" = {
    force = true;
    source = ./config/commands/sq/reflect.toml;
  };
  home.file."${qwenHome}/commands/sq/save.toml" = {
    force = true;
    source = ./config/commands/sq/save.toml;
  };
  home.file."${qwenHome}/commands/sq/select-tool.toml" = {
    force = true;
    source = ./config/commands/sq/select-tool.toml;
  };
  home.file."${qwenHome}/commands/sq/test.toml" = {
    force = true;
    source = ./config/commands/sq/test.toml;
  };
  home.file."${qwenHome}/commands/sq/troubleshoot.toml" = {
    force = true;
    source = ./config/commands/sq/troubleshoot.toml;
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
      OPENAI_API_KEY="sk-not-required-for-ollama"
      OPENAI_API_BASE="http://localhost:11434/v1/"
      OPENAI_MODEL="hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q4_K_XL"
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
