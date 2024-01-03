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
      enableNushellIntegration = mkIf config.nu.enable true;
      nix-direnv.enable = true;
    };
  };
}