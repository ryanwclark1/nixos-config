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
    # This bash build was compiled without programmable completion support
    # (`shopt progcomp` and `complete` are unavailable), so Home Manager's
    # generic bash-completion init fails on startup.
    enableCompletion = false;

    bashrcExtra = ''
      export HISTSIZE=100000
      export SAVEHIST=100000

      export LESS_TERMCAP_mb=$'\e[1;32m'
      export LESS_TERMCAP_md=$'\e[1;32m'
      export LESS_TERMCAP_me=$'\e[0m'
      export LESS_TERMCAP_se=$'\e[0m'
      export LESS_TERMCAP_so=$'\e[01;33m'
      export LESS_TERMCAP_ue=$'\e[0m'
      export LESS_TERMCAP_us=$'\e[1;4;31m'

      # Initialize fnm (Fast Node Manager)
      if command -v fnm &> /dev/null; then
        eval "$(fnm env --use-on-cd --shell bash)"
      fi

      # Source common shell functions
      if [ -f "$HOME/.config/shell/functions.sh" ]; then
        source "$HOME/.config/shell/functions.sh"
      fi
    '';
  };

}
