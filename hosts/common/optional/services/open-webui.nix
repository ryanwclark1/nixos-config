{
  pkgs,
  ...
}:

{
  networking.firewall = {
    allowedTCPPorts = [
      8180 # open-webui
    ];
  };

  services.open-webui = {
    enable = false;
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

      # MCP support is now configured at the user level via home-manager
      # See: home/features/ai/mcp-openwebui.nix
      # MCP servers are launched on-demand by clients, not as persistent services
    };
  };
}
