{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    lmstudio
    claude-code
    aider-chat-full
  ];
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    port = 11434;
  };
}
