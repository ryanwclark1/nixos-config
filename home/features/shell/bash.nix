{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Enhanced bash configuration with modern tooling
  programs.bash = {
    enable = true;
    enableCompletion = true;

    bashrcExtra = ''
      # Initialize fnm (Fast Node Manager)
      if command -v fnm &> /dev/null; then
        eval "$(fnm env --use-on-cd --shell bash)"
      fi
    '';
  };

}
