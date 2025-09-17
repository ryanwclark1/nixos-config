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

    # Claude Code zoxide compatibility fix
    # Ensures cd works properly even when shell snapshots contain broken functions
    if command -v zoxide > /dev/null 2>&1; then
      # Check if __zoxide_z function exists and is callable
      if ! command -v __zoxide_z > /dev/null 2>&1; then
        # Create a robust cd function that falls back to builtin cd
        cd() {
          builtin cd "$@"
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

    '';
  };

}
