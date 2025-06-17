{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    lmstudio
  ];
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    port = 11434;
  };
}



