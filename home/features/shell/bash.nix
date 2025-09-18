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
      # Skip initialization for non-interactive shells early
      [[ $- != *i* ]] && return

      # Safer handling for restricted environments
      # Only enable restricted mode if bash is actually restricted
      if [[ -n "$BASH_EXECUTION_STRING" ]] || ! shopt -q restricted_shell 2>/dev/null; then
        # Normal bash - full features enabled
        :
      else
        # Restricted shell detected
        export BASH_RESTRICTED_MODE=1
      fi

      # VS Code specific handling - not necessarily restricted, just different
      if [[ -n "$VSCODE_INJECTION" ]] || [[ "$TERM_PROGRAM" == "vscode" ]]; then
        # VS Code terminal - be cautious with blesh
        export VSCODE_TERMINAL=1
      fi

      # Only apply shell options if not in restricted mode
      if [[ -z "$BASH_RESTRICTED_MODE" ]]; then
        # Test if shopt works before using it
        if shopt -o nounset 2>/dev/null; then
          # shopt is available and working
          :
        else
          # shopt is not available or restricted
          export BASH_RESTRICTED_MODE=1
        fi
      fi

      # Enhanced prompt command for updating terminal title
      PROMPT_COMMAND='history -a; history -n; printf "\033]0;%s@%s:%s\007" "''${USER}" "''${HOSTNAME%%.*}" "''${PWD/#$HOME/\~}"'

      # Bash-specific completion enhancements (only if not restricted)
      if [[ -z "$BASH_RESTRICTED_MODE" ]] && command -v bind &>/dev/null 2>&1; then
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
      if [[ -z "$BASH_RESTRICTED_MODE" ]] && ! command -v atuin &> /dev/null && command -v fzf &> /dev/null; then
        if command -v bind &>/dev/null 2>&1; then
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
      if [[ -z "$BASH_RESTRICTED_MODE" ]]; then
        shopt -s cdable_vars 2>/dev/null || true
      fi
      export dl="$HOME/Downloads"
      export docs="$HOME/Documents"
      export dev="$HOME/Code"
      export nix="$HOME/nixos-config"
      export dots="$HOME/.config"
    '';

    initExtra = ''
      # Skip complex initialization in truly restricted environments
      if [[ -n "$BASH_RESTRICTED_MODE" ]]; then
        # Minimal setup for restricted environments
        if [ -f "$HOME/.config/shell/functions.sh" ]; then
          source "$HOME/.config/shell/functions.sh"
        fi
        return
      fi

      # Initialize blesh if available and not in VS Code (where it may cause issues)
      if [[ -z "$VSCODE_TERMINAL" ]] && [[ -f "${pkgs.blesh}/share/blesh/ble.sh" ]]; then
        source "${pkgs.blesh}/share/blesh/ble.sh" --noattach 2>/dev/null || true
        
        # Attach blesh only if initialization succeeded
        if declare -f ble-attach &>/dev/null; then
          ble-attach 2>/dev/null || true
        fi
      fi

      # Enhanced FZF completion preview customization
      # This complements the basic integration from programs.fzf
      if command -v fzf &> /dev/null; then
        show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat --style=numbers --color=always --line-range=:500 {}; fi"

        # Custom preview for different completion contexts
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
