{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options.ollama.enable = mkEnableOption "ollama settings";
  config = mkIf config.ollama.enable {
    home.packages = with pkgs; [ollama];
  };
}