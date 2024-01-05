# Similar to TMUX
{
  lib,
  config,
  ...
}:

with lib; {
  options.zellij.enable = mkEnableOption "zellij settings";

  config = mkIf config.zellij.enable {
    programs.zellij = {
      enable = true;
      package = pkgs.zellij;
      # https://zellij.dev/documentation
      # settings = {};
      enableZshIntegration = true;
      enableFishIntegration = true;
      enableBashIntegration = true;
    };
  };
}