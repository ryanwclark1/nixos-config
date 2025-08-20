{
  pkgs,
  ...
}:

{
  imports = [
    ./mcp-openwebui.nix
  ];
  home.packages = with pkgs; [
    lmstudio
    mlflow-server
    # claude-code
    # aider-chat
    
    # MCP support
    (python3.withPackages (ps: with ps; [
      # Install mcpo for MCP proxy functionality
    ]))
    uv  # For installing mcpo and MCP servers
  ];

}

