{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./mcp-openwebui.nix
    ./sourcebot.nix  # Docker Compose-based Sourcebot with PostgreSQL and Redis
    ./gemini-cli-override.nix  # Custom gemini-cli version override
    # ./open-webui-docker.nix
  ];
  home.packages = with pkgs; [
    lmstudio
    # mlflow-server  # Temporarily disabled due to missing fastapi/uvicorn dependencies
    # claude-code
    # aider-chat

    amp-cli
    codex
    crush
    goose-cli
    claude-code
    qwen-code
    # gemini-cli  # Using override instead (imported above)

    # Docker for running MCP servers
    docker
    docker-compose
  ];

    # Set global environment variables for MCP integration
  home.sessionVariables = {
    # Standard MCP configuration paths
    MCP_CONFIG_FILE = "${config.home.homeDirectory}/.config/open-webui/mcp-servers-processed.json";
    MCP_SERVERS_CONFIG = "${config.home.homeDirectory}/.config/open-webui/mcp-servers-processed.json";

    # Tool-specific environment variables
    AIDER_MCP_CONFIG = "${config.home.homeDirectory}/.config/open-webui/mcp-servers-processed.json";
    CLAUDE_CODE_MCP_CONFIG = "${config.home.homeDirectory}/.config/open-webui/mcp-servers-processed.json";
    GOOSE_MCP_CONFIG = "${config.home.homeDirectory}/.config/open-webui/mcp-servers-processed.json";
    QWEN_MCP_CONFIG = "${config.home.homeDirectory}/.config/open-webui/mcp-servers-processed.json";
    GEMINI_MCP_CONFIG = "${config.home.homeDirectory}/.config/open-webui/mcp-servers-processed.json";

    # Generic fallbacks
    MCP_TRANSPORT = "stdio";
    MCP_CONFIG = "${config.home.homeDirectory}/.config/open-webui/mcp-servers-processed.json";
  };

  # Shell functions to ensure MCP integration when running tools directly
  home.shellAliases = {
    # Override CLI tools to automatically include MCP support
    "aider" = "aider --mcp \"$MCP_CONFIG_FILE\"";
    "goose" = "goose --mcp-config \"$MCP_CONFIG_FILE\"";
    "gemini-cli" = "gemini-cli --mcp \"$MCP_CONFIG_FILE\"";
    # Note: claude-code, codex, qwen-code, crush use environment variables
  };

  # Create MCP configuration directory and files
  home.file.".config/open-webui/mcp-servers.json".source = ./mcp-servers.json;

  # Create Qwen Code environment configuration
  home.file.".qwen/.env".text = ''
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
  '';

  # Create a template for project-specific Qwen Code settings
  home.file.".config/qwen/project-env-template".text = ''
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

}

