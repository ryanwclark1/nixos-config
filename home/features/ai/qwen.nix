{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Official user-level settings & dirs (per docs)
  qwenHome = "${config.home.homeDirectory}/.qwen";
  settingsPath = "${qwenHome}/settings.json";

  # Import MCP servers configuration
  mcpServersRaw = builtins.fromJSON (builtins.readFile ./mcp-servers.json);
  mcpServers = mcpServersRaw;
in
{

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

  # Create Qwen Code environment configuration
  home.file.".qwen/.env" = {
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
      CONTEXT7_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.context7-token.path})
      GITHUB_PERSONAL_ACCESS_TOKEN=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.github-pat.path})
      SOURCEBOT_API_KEY=$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."sourcebot/api-key".path})
    '';
    onChange = ''
      # Expand SOPS secrets in .env file
      if [ -f "${qwenHome}/.env" ]; then
        tmp=$(${pkgs.coreutils}/bin/mktemp)
        while IFS= read -r line; do
          if [[ "$line" =~ ^([A-Z_]+)=\$\((.+)\)$ ]]; then
            var_name="''${BASH_REMATCH[1]}"
            cmd="''${BASH_REMATCH[2]}"
            value=$(eval "$cmd" 2>/dev/null || echo "")
            echo "$var_name=$value" >> "$tmp"
          else
            echo "$line" >> "$tmp"
          fi
        done < "${qwenHome}/.env"
        ${pkgs.coreutils}/bin/mv "$tmp" "${qwenHome}/.env"
      fi
    '';
  };

  # Create a template for project-specific Qwen Code settings
  home.file.".qwen/project-settings-template.json".text = builtins.toJSON {
    # Project-specific overrides for settings.json
    # Copy this to your project root as .qwen/settings.json

    # Override model for this project
    model = "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q4_K_XL";

    # Project-specific UI preferences
    showLineNumbers = true;
    hideFooter = false;

    # Project-specific performance settings
    maxSessionTurns = 100;
    sessionTokenLimit = 128000;

    # Project-specific file filtering
    fileFiltering = {
      respectGitIgnore = true;
      respectGeminiIgnore = true;
      enableRecursiveFileSearch = true;
    };

    # Project-specific content generator settings
    contentGenerator = {
      timeout = 60000; # 60 seconds for larger projects
      maxRetries = 5;
      disableCacheControl = false;
    };

    # Project-specific includes
    includeDirectories = [ "./docs" "./examples" ];
    loadMemoryFromIncludeDirectories = true;

    # Project context file
    contextFileName = [ "QWEN.md" "README.md" "CONTEXT.md" ];
  };

  # Create a template for project-specific Qwen Code environment
  home.file.".qwen/project-env-template".text = ''
    # Project-specific Qwen Code Configuration Template
    # Copy this to your project root as .qwen/.env or .env
    #
    # Note: Some variables like DEBUG and DEBUG_MODE are automatically
    # excluded from project .env files by qwen-code

    # Override global model for this project (optional)
    # MODEL=hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q4_K_XL

    # Project-specific MCP servers (optional)
    # MCP_CONFIG_FILE=./project-mcp-servers.json

    # Project-specific code style
    QWEN_CODE_STYLE=detailed
    QWEN_EXPLAIN_LEVEL=verbose

    # Context settings for this project
    MAX_TOKENS=12288
    TEMPERATURE=0.05

    # Project-specific preferences
    # QWEN_AUTO_COMMIT=false
    # QWEN_BACKUP_FILES=true
  '';

  # # Create a launcher script for Qwen Code with environment
  # home.file.".local/bin/qwen-code-launch" = {
  #   text = ''
  #     #!/usr/bin/env bash

  #     # Load Qwen Code environment
  #     if [ -f "$HOME/.qwen/.env" ]; then
  #       export $(grep -v '^#' "$HOME/.qwen/.env" | xargs)
  #     fi

  #     # Load project-specific environment if exists
  #     if [ -f ".qwen/.env" ]; then
  #       export $(grep -v '^#' ".qwen/.env" | xargs)
  #     elif [ -f ".env" ]; then
  #       export $(grep -v '^#' ".env" | xargs)
  #     fi

  #     # Launch Qwen Code
  #     exec qwen-code "$@"
  #   '';
  #   executable = true;
  # };

  # # Add shell alias for convenient launching
  # programs.bash.shellAliases = {
  #   qc = "qwen-code-launch";
  #   qwen = "qwen-code-launch";
  # };

  # programs.zsh.shellAliases = {
  #   qc = "qwen-code-launch";
  #   qwen = "qwen-code-launch";
  # };

}
