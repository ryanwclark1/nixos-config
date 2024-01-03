{
  lib,
  pkgs,
  config,
  ...
}:
with lib; {
  options.skim.enable = mkEnableOption "skim settings";
  config = mkIf config.skim.enable {
    programs.skim = {
      enable = true;
      enableZshIntegration = config.zsh.enable;
      enableFishIntegration = config.fish.enable;
      enableBashIntegration = config.bash.enable;
      defaultCommand = "rg --files --hidden";
      changeDirWidgetOptions = [
        "--preview 'eza --icons --git --color always -T -L 3 {} | head -200'"
        "--exact"
      ];
    };
    home.packages = with pkgs; [fd];
  };
}
