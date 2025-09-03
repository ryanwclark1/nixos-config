{
  pkgs,
  ...
}:

{
  imports = [
    ./mcp-openwebui.nix
    ./sourcebot.nix  # Docker Compose-based Sourcebot with PostgreSQL and Redis
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
    gemini-cli

    # Docker for running MCP servers
    docker
    docker-compose
  ];

}

