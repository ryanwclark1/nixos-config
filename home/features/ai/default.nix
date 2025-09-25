{
  config,
  pkgs,
  ...
}:

{
  imports = [
    # ./mcp-openwebui.nix
    # ./sourcebot.nix  # Docker Compose-based Sourcebot with PostgreSQL and Redis
    ./gemini-cli.nix  # Custom gemini-cli version override
    # ./open-webui-docker.nix
    ./claude  # Currently missing
    ./qwen.nix
    ./codex.nix
  ];
  home.packages = with pkgs; [
    lmstudio
    # mlflow-server  # Temporarily disabled due to missing fastapi/uvicorn dependencies
    # aider-chat

    playwright-mcp
    # Required for Sourcebot MCP server
    amp-cli
    # codex
    crush
    goose-cli

    # Docker for running MCP servers
    docker
    docker-compose
  ];

}

