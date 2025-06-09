{

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
    shellGlobalAliases = {
      "--help" = "--help 2>&1 | bat --language=help --style=plain";
    };
    initContent = ''
    show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat --style=numbers --color=always --line-range=:500 {}; fi"

    _fzf_comprun() {
      local command=$1
      shift

      case "$command" in
        cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
        export|unset) fzf --preview "eval 'echo \''\${}'"         "$@" ;;
        ssh)          fzf --preview 'dig {}'                   "$@" ;;
        *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
      esac
    }

    # Zoxide integration with error handling and fallback
    if command -v zoxide > /dev/null 2>&1; then
      # Initialize zoxide with error handling
      if eval "$(zoxide init --cmd cd zsh 2>/dev/null)"; then
        # Successfully initialized zoxide
        :
      else
        # Fallback: create a simple cd wrapper that tries zoxide then falls back to builtin cd
        cd() {
          if command -v __zoxide_z > /dev/null 2>&1; then
            __zoxide_z "$@" 2>/dev/null || builtin cd "$@"
          else
            builtin cd "$@"
          fi
        }
      fi
    fi
    
    # Docker helper functions for non-interactive environments
    docker-exec() {
      local container="$1"
      shift
      if [ -t 0 ] && [ -t 1 ]; then
        # Interactive terminal available
        docker exec -it "$container" "$@"
      else
        # Non-interactive environment (like Claude Code)
        docker exec "$container" "$@"
      fi
    }
    
    # Common Docker patterns with fallback
    docker-bash() {
      local container="$1"
      shift
      if [ -t 0 ] && [ -t 1 ]; then
        docker exec -it "$container" bash "$@"
      else
        docker exec "$container" bash "$@"
      fi
    }
    
    docker-sh() {
      local container="$1"
      shift
      if [ -t 0 ] && [ -t 1 ]; then
        docker exec -it "$container" sh "$@"
      else
        docker exec "$container" sh "$@"
      fi
    }

    # alias claude="/home/administrator/.claude/local/claude"
    '';
  };

}
