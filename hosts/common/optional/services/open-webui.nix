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
    };
  };
}

