{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./mcp-openwebui.nix
    ./sourcebot.nix  # Docker Compose-based Sourcebot with PostgreSQL and Redis
    ./gemini-cli.nix  # Custom gemini-cli version override
    # ./open-webui-docker.nix
    ./claude.nix
    ./qwen.nix
  ];
  home.packages = with pkgs; [
    lmstudio
    # mlflow-server  # Temporarily disabled due to missing fastapi/uvicorn dependencies
    # aider-chat

    playwright-mcp
    # Required for Sourcebot MCP server
    amp-cli
    codex
    crush
    goose-cli


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
    # CLAUDE_CODE_MCP_CONFIG = "${config.home.homeDirectory}/.config/open-webui/mcp-servers-processed.json";
    GOOSE_MCP_CONFIG = "${config.home.homeDirectory}/.config/open-webui/mcp-servers-processed.json";
    QWEN_MCP_CONFIG = "${config.home.homeDirectory}/.config/open-webui/mcp-servers-processed.json";
    # GEMINI_MCP_CONFIG = "${config.home.homeDirectory}/.config/open-webui/mcp-servers-processed.json";

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

}

