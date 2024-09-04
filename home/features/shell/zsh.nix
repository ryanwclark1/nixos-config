{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.zsh = {
    enable = true;
    package = pkgs.zsh;
    enableCompletion = true;
    enableVteIntegration = true;
    # defaultKeymap = "vicmd";
    syntaxHighlighting = {
      enable = true;
    };
    autosuggestion = {
      enable = true;
    };
  };

  programs.atuin.enableZshIntegration = lib.mkIf config.programs.atuin.enable true;
  programs.eza.enableZshIntegration = lib.mkIf config.programs.eza.enable true;
  programs.fzf.enableZshIntegration = lib.mkIf config.programs.fzf.enable true;
  programs.kitty.shellIntegration.enableZshIntegration = lib.mkIf config.programs.kitty.enable true;
  programs.nix-index.enableZshIntegration = lib.mkIf config.programs.nix-index.enable true;
  programs.starship.enableZshIntegration = lib.mkIf config.programs.starship.enable true;
  programs.zoxide.enableZshIntegration = lib.mkIf config.programs.zoxide.enable true;
  programs.yazi.enableZshIntegration = lib.mkIf config.programs.yazi.enable true;
  programs.zellij.enableZshIntegration = lib.mkIf config.programs.zellij.enable false;

}
