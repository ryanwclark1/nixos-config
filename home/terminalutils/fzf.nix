# TODO add config for fzf
# A command-line fuzzy finder
{
  pkgs,
  lib,
  config,
  ...
}:

with lib; {
  options.fzf.enable = mkEnableOption "fzf settings";

  config = mkIf config.fzf.enable {
    programs.fzf = {
      enable = true;
      changeDirWidgetCommand = "fd --type d";
      tmux.enableShellIntegration = config.tmux.enable;
      enableBashIntegration = config.bash.enable;
      enableZshIntegration = config.zsh.enable;
      enableFishIntegration = config.fish.enable;
    };

    home.packages = with pkgs; [
      skim
    ];
  };
}
