{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    lmstudio
    # claude-code
    # aider-chat
  ];
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    port = 11434;
  };
}
