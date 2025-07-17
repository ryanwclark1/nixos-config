{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    lmstudio
    mlflow-server
    # claude-code
    # aider-chat
  ];
  # services.open-webui = {
  #   enable = true;
  #   port = 8180;
  #   host = "127.0.0.1";
  #   openFirewall = true;
  #   package = pkgs.open-webui;
  #   environment = {
  #     ANONYMIZED_TELEMETRY = "False";
  #     DO_NOT_TRACK = "True";
  #     SCARF_NO_ANALYTICS = "True";
  #     OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
  #     WEBUI_AUTH = "False";
  #   };
  # };
}

