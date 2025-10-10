{
  config,
  pkgs,
  ...
}:

{
  imports = [
    # ./mcp-openwebui.nix
    # ./sourcebot.nix  # Docker Compose-based Sourcebot with PostgreSQL and Redis
    # ./gemini-cli.nix  # Custom gemini-cli version override
    # ./open-webui-docker.nix
    ./claude  # Currently missing
    ./crush
    ./gemini
    ./qwen
    ./codex
    ./opencode
  ];
  home.packages = with pkgs; [
    lmstudio
    # mlflow-server  # Temporarily disabled due to missing fastapi/uvicorn dependencies
    playwright-mcp
    # Required for Sourcebot MCP server
    amp-cli
    goose-cli
    aider-chat-full

    # Docker for running MCP servers
    docker
    docker-compose
  ];

}

