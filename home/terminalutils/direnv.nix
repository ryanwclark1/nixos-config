# direnv is an extension for your shell.
# It augments existing shells with a new feature that can load and unload environment variables depending on the current directory.
{
  lib,
  config,
  ...
}:
with lib; {
  options.direnv.enable = mkEnableOption "direnv settings";

  config = mkIf config.direnv.enable {
    programs.direnv = {
      enable = true;
      enableBashIntegration = mkIf config.bash.enable true;
      enableZshIntegration = mkIf config.zsh.enable true;
      # enableFishIntegration = mkIf config.fish.enable true;
      enableNushellIntegration = mkIf config.nushell.enable true;
      nix-direnv.enable = true;
    };
  };
}