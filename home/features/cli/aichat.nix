# Use GPT-4(V), Gemini, LocalAI, Ollama and other LLMs in the terminal.

{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    aichat
  ];
}
