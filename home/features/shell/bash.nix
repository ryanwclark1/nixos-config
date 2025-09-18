{
  config,
  pkgs,
  lib,
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

    # History configuration - matching ZSH's robust history
    historySize = 100000;
    historyFileSize = 100000;
    historyFile = "${config.home.homeDirectory}/.config/bash/history";
    historyControl = [
      "erasedups"  # Remove duplicate entries
      "ignorespace" # Don't save commands starting with space
      "ignoredups" # Don't save duplicate commands
    ];
    historyIgnore = [
      "ls"
      "cd"
      "cd -"
      "pwd"
      "exit"
      "date"
      "* --help"
      "history"
      "clear"
      "rm *"
      "pkill *"
      "kill *"
    ];

    # Shell options for better interactive experience
    shellOptions = [
      # History options
      "histappend"  # Append to history file, don't overwrite
      "histverify"  # Review history substitution before executing
      "histreedit"  # Allow re-editing of failed history substitutions

      # Completion and expansion options
      "cdspell"     # Correct minor spelling errors in cd commands
      "dirspell"    # Spell check directory names during completion
      "dotglob"     # Include hidden files in pathname expansion
      "extglob"     # Extended pattern matching
      "globstar"    # ** matches all files recursively
      "nocaseglob"  # Case-insensitive pathname expansion
      "nocasematch" # Case-insensitive pattern matching

      # Job control
      "checkjobs"   # Check for running jobs before exiting
      "huponexit"   # Send SIGHUP to all jobs on exit

      # Interactive behavior
      "autocd"      # cd into directory by typing its name
      "cdable_vars" # cd into variable values
      "checkwinsize" # Update LINES and COLUMNS after each command
      "cmdhist"     # Save multi-line commands as single history entry
      "direxpand"   # Expand directory names on completion
      "lithist"     # Save multi-line commands with newlines

      # Error handling
      "no_empty_cmd_completion" # Don't complete on empty command line
    ];

    # Bash-specific session variables
    sessionVariables = {
      BASH_INTERACTIVE = "${pkgs.bashInteractive}/bin/bash";
    };

    # Bash-specific shell aliases (inherits from common.nix)
    shellAliases = {
      # Bash-specific quick edits
      bashrc = "$EDITOR ~/.bashrc";

      # Bash-specific reload
      reload = "exec bash";
    };

    profileExtra = ''
      # Additional bash profile customizations can go here
    '';

    bashrcExtra = ''
      # Override shopt to handle restricted shells gracefully
      if ! type shopt &>/dev/null 2>&1; then
        shopt() { return 0; }
        export -f shopt
      else
        # Wrap original shopt to suppress errors
        _original_shopt=$(which shopt 2>/dev/null || echo shopt)
        shopt() {
          $_original_shopt "$@" 2>/dev/null || return 0
        }
        export -f shopt
      fi

      # Override complete builtin if it doesn't exist
      if ! type complete &>/dev/null 2>&1; then
        complete() { return 0; }
        builtin() {
          case "$1" in
            complete) return 0 ;;
            *) command builtin "$@" 2>/dev/null || return 0 ;;
          esac
        }
        export -f complete
        export -f builtin
      fi

      # Skip further initialization for non-interactive shells
      [[ $- != *i* ]] && return

      # Enhanced prompt command for updating terminal title
      PROMPT_COMMAND='history -a; history -n; printf "\033]0;%s@%s:%s\007" "''${USER}" "''${HOSTNAME%%.*}" "''${PWD/#$HOME/\~}"'

      # Bash-specific completion enhancements (only if bind is available)
      if command -v bind &>/dev/null 2>&1 || builtin bind 2>/dev/null; then
        bind "set completion-ignore-case on" 2>/dev/null || true
        bind "set completion-map-case on" 2>/dev/null || true
        bind "set show-all-if-ambiguous on" 2>/dev/null || true
        bind "set mark-symlinked-directories on" 2>/dev/null || true
        bind "set colored-stats on" 2>/dev/null || true
        bind "set visible-stats on" 2>/dev/null || true
        bind "set page-completions off" 2>/dev/null || true
        bind "set menu-complete-display-prefix on" 2>/dev/null || true
        bind "set completion-query-items 200" 2>/dev/null || true

        # Better history search with arrow keys
        bind '"\e[A": history-search-backward' 2>/dev/null || true
        bind '"\e[B": history-search-forward' 2>/dev/null || true
        bind '"\e[C": forward-char' 2>/dev/null || true
        bind '"\e[D": backward-char' 2>/dev/null || true
      fi

      # Ctrl+R handled by atuin if available, fallback to fzf
      if ! command -v atuin &> /dev/null && command -v fzf &> /dev/null; then
        if command -v bind &>/dev/null 2>&1 || builtin bind 2>/dev/null; then
          bind -x '"\C-r": __fzf_history' 2>/dev/null || true
          __fzf_history() {
            local output
            output=$(history | fzf --tac --no-sort --exact --query "$READLINE_LINE" | sed 's/^[ ]*[0-9]*[ ]*//')
            READLINE_LINE=$output
            READLINE_POINT=''${#READLINE_LINE}
          }
        fi
      fi

      # Directory shortcuts (similar to ZSH's hash -d)
      shopt -s cdable_vars 2>/dev/null || true
      export dl="$HOME/Downloads"
      export docs="$HOME/Documents"
      export dev="$HOME/Code"
      export nix="$HOME/nixos-config"
      export dots="$HOME/.config"
    '';

    initExtra = ''
      # FZF integration for file and directory preview
      if command -v fzf &> /dev/null; then
        show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat --style=numbers --color=always --line-range=:500 {}; fi"

        _fzf_comprun() {
          local command=$1
          shift

          case "$command" in
            cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
            export|unset) fzf --preview 'printenv {}' "$@" ;;
            ssh)          fzf --preview 'dig {}' "$@" ;;
            *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
          esac
        }

        # Setup fzf key bindings if available
        if [ -f "${pkgs.fzf}/share/fzf/key-bindings.bash" ]; then
          source "${pkgs.fzf}/share/fzf/key-bindings.bash"
        fi

        if [ -f "${pkgs.fzf}/share/fzf/completion.bash" ]; then
          source "${pkgs.fzf}/share/fzf/completion.bash"
        fi
      fi

      # Source common shell functions
      if [ -f "$HOME/.config/shell/functions.sh" ]; then
        source "$HOME/.config/shell/functions.sh"
      fi

      # Better command not found handler
      command_not_found_handle() {
        local cmd="$1"
        if command -v nix-locate &> /dev/null; then
          echo "Command '$cmd' not found. Searching in nixpkgs..." >&2
          nix-locate --top-level --minimal --at-root "/bin/$cmd"
        else
          echo "bash: $cmd: command not found" >&2
        fi
        return 127
      }
    '';

    logoutExtra = ''
      # Clear screen on logout
      clear

      # Save history
      history -a
    '';
  };
}
