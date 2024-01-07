# Terminal history search
# https://atuin.sh/docs/
# Updated when enter is pressed select not execute.
# TODO: temp disabled up arrow
{
  config,
  lib,
  ...
}:
with lib; {
  options.atuin.enable = mkEnableOption "atuin settings";

  config = mkIf config.atuin.enable {
    programs.atuin = {
      enable = true;
      flags = ["--disable-up-arrow"];
      enableBashIntegration = config.bash.enable;
      enableFishIntegration = config.fish.enable;
      enableNushellIntegration = config.nushell.enable;
      enableZshIntegration = config.zsh.enable;
    };
  };
}