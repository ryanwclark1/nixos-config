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
