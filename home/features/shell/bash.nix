{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    blesh
  ];

  programs.bash = {
    enable = true;
    package = pkgs.bashInteractive;
    enableCompletion = true;
    enableVteIntegration = true;
    initExtra = ''
      # if [ -x "$(command -v fastfetch)" ]; then
      #   fastfetch 2>/dev/null
      # fi
      # alias claude="/home/administrator/.claude/local/claude"
      
      # Zoxide integration with error handling and fallback
      if command -v zoxide > /dev/null 2>&1; then
        # Initialize zoxide with error handling
        if eval "$(zoxide init --cmd cd bash 2>/dev/null)"; then
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
    '';
  };
}
