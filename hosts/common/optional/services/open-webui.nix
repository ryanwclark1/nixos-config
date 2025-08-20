{
  pkgs,
  ...
}:

{
  services.open-webui = {
    enable = true;
    port = 8180;
    host = "0.0.0.0";
    openFirewall = true;
    package = pkgs.open-webui;
    environment = {
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
      WEBUI_AUTH = "False";
      VECTOR_DB = "chroma";
      CHROMA_HTTP_PORT = "8181";
      
      # MCP Server endpoints for Open WebUI
      # These will be available as OpenAPI endpoints for tool usage
      MCP_FILESYSTEM_API = "http://localhost:8200";
      MCP_GIT_API = "http://localhost:8201";  
      MCP_MEMORY_API = "http://localhost:8202";
      MCP_TIME_API = "http://localhost:8203";
      MCP_FETCH_API = "http://localhost:8204";
    };
  };
  
  # Open firewall ports for MCP servers
  networking.firewall.allowedTCPPorts = [ 8200 8201 8202 8203 8204 ];
}

