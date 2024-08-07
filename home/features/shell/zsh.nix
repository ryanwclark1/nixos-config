{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableVteIntegration = true;
    syntaxHighlighting = {
      enable = true;
    };
    autosuggestion = {
      enable = true;
    };
    # localVariables = {
    #   DISABLE_CORRECTION = true;
    # };
    # autocd = true;
    # initExtra = ''
    #   # eval "$(zellij setup --generate-auto-start zsh)"
    #   # if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
    #   			# exec tmux
    #   # fi

    #   # export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS"
    #   # --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 \
    #   # --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 \
    #   # --color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796"
    # '';
    # dotDir = ".config/zsh";
    # completionInit = "autoload -U compinit && compinit";
    # history.expireDuplicatesFirst = true;
    # history.extended = true;
    # history.ignoreDups = true;
    # history.save = 3000000;
    # history.size = 30000000;
  };
  programs.atuin.enableZshIntegration = mkIf config.programs.atuin.enable true;
  programs.eza.enableZshIntegration = mkIf config.programs.eza.enable true;
  programs.fzf.enableZshIntegration = mkIf config.programs.fzf.enable true;
  programs.nix-index.enableZshIntegration = mkIf config.programs.nix-index.enable true;
  programs.starship.enableZshIntegration = mkIf config.programs.starship.enable true;
  programs.zoxide.enableZshIntegration = mkIf config.programs.zoxide.enable true;
}
