{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  programs.zsh = {
    enable = true;
    package = pkgs.zsh;
    enableCompletion = true;
    enableVteIntegration = true;
    defaultKeymap = "vicmd";
    syntaxHighlighting = {
      enable = true;
    };
    autosuggestion = {
      enable = true;
    };
  };
  
  programs.atuin.enableZshIntegration = mkIf config.programs.atuin.enable true;
  programs.eza.enableZshIntegration = mkIf config.programs.eza.enable true;
  programs.fzf.enableZshIntegration = mkIf config.programs.fzf.enable true;
  programs.nix-index.enableZshIntegration = mkIf config.programs.nix-index.enable true;
  programs.starship.enableZshIntegration = mkIf config.programs.starship.enable true;
  programs.zoxide.enableZshIntegration = mkIf config.programs.zoxide.enable true;
  programs.yazi.enableZshIntegration = mkIf config.programs.yazi.enable true;
  programs.zellij.enableZshIntegration = mkIf config.programs.zellij.enable true;

}
