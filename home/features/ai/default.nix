{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./claude
    ./crush
    ./gemini
    ./goose
    ./qwen
    ./codex
    ./opencode
  ];
  home.packages = with pkgs; [
    lmstudio
    mlflow-server  # Temporarily disabled due to missing fastapi/uvicorn dependencies
    playwright-mcp
    amp-cli
    aider-chat-full

    # Docker for running MCP servers
    docker
    docker-compose
  ];

}

