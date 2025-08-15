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

}

