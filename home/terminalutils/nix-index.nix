# A wonderful CLI to track your time!
{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  options.nix-index.enable = mkEnableOption "nix-index settings";

  config = mkIf config.nix-index.enable {
    programs.nix-index = {
      enable = true;
      package = pkgs.nix-index;
      enableBashIntegration = config.zsh.enable;
      enableZshIntegration = config.zsh.enable;
      enableFishIntegration = config.zsh.enable;

    };
  };
}
