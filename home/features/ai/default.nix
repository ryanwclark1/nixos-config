{
  pkgs,
  ...
}:

{
  imports = [
    ./mcp-openwebui.nix
    ./sourcebot.nix  # Docker Compose-based Sourcebot with PostgreSQL and Redis
    ./open-webui-docker.nix
  ];
  home.packages = with pkgs; [
    lmstudio
    # mlflow-server  # Temporarily disabled due to missing fastapi/uvicorn dependencies
    # claude-code
    # aider-chat
    
    # Docker for running MCP servers
    docker
    docker-compose
    
    # MCP support - MCPO proxy for MCP-to-OpenAPI conversion
    (python3.withPackages (ps: with ps; [
      # Install mcpo for MCP proxy functionality
    ]))
  ];

}

