{
  lib,
  programs,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    enableVteIntegration = true;
    localVariables = {
      DISABLE_CORRECTION = true;
    };
    autocd = true;
    initExtra = ''
      # eval "$(zellij setup --generate-auto-start zsh)"
      # if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
      			# exec tmux
      # fi

      # export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS"
      # --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 \
      # --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 \
      # --color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796"
    '';
    dotDir = ".config/zsh";
    completionInit = "autoload -U compinit && compinit";
    history.expireDuplicatesFirst = true;
    history.extended = true;
    history.ignoreDups = true;
    history.save = 3000000;
    history.size = 30000000;
  };

  programs.fzf.enableZshIntegration = true;
  programs.nix-index.enableZshIntegration = true;
  programs.starship.enableZshIntegration = true;
  programs.zoxide.enableZshIntegration = true;
  # services.gpg-agent.enableZshIntegration = mkIf config.gpg-agent.enable true;
}
