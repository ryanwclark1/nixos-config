{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./aichat
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
    # mlflow-server  # Temporarily disabled due to missing fastapi/uvicorn dependencies
    playwright-mcp
    amp-cli
    # aider-chat-full  # Temporarily disabled due to mercantile package build failure

    # Docker for running MCP servers
    docker
    docker-compose
  ];

}

