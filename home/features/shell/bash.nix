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
    package = pkgs.bashInteractive;
    enableCompletion = true;  # Re-enabled with Carapace handling completions
    enableVteIntegration = true;  # Re-enabled for better terminal integration

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

    shellOptions = [
      # History options
      "histappend"  # Append to history file
      "histverify"  # Verify history expansion before execution
      # Completion and expansion options
      "cdspell"     # Correct minor spelling errors in cd commands
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
      "lithist"     # Save multi-line commands with newlines
      # Error handling and safety
      "inherit_errexit" # Child processes inherit errexit
      "interactive_comments" # Allow comments in interactive shell
      "failglob"    # Fail on glob patterns that don't match
      "nullglob"    # Expand globs to empty string if no matches
      # Modern bash features
      "assoc_expand_once" # Only expand associative arrays once
      "autocd"      # Change to directory if command is directory name
    ];

    # Bash-specific session variables
    sessionVariables = {
      BASH_INTERACTIVE = "${pkgs.bashInteractive}/bin/bash";
      # Enhanced bash-specific variables
      BASH_SILENCE_DEPRECATION_WARNING = "1";  # Silence macOS deprecation warnings
      BASH_COMPLETION_USER_FILE = "${config.home.homeDirectory}/.config/bash/bash_completion";
    };

    # Bash-specific shell aliases (inherits from common.nix)
    shellAliases = {
      # Bash-specific quick edits
      bashrc = "$EDITOR ~/.bashrc";
      bashprofile = "$EDITOR ~/.bash_profile";

      # Bash-specific reload
      reload = "exec bash";
      reload-profile = "source ~/.bash_profile";

      # Enhanced bash-specific utilities
      bash-version = "echo \"Bash version: $BASH_VERSION\"";
      bash-options = "set -o";
      bash-functions = "declare -f";
    };

    profileExtra = ''
      # Bash profile customizations
      # This runs for login shells (SSH, terminal login, etc.)

      # Ensure we have a proper PATH
      if [[ -z "$PATH_SETUP" ]]; then
        export PATH_SETUP=1
        # Add local bin directories if they exist
        for dir in "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/go/bin"; do
          if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
            PATH="$dir:$PATH"
          fi
        done
      fi
    '';

    bashrcExtra = ''
      # Skip initialization for non-interactive shells early
      [[ $- != *i* ]] && return

      # Ensure terminal supports colors
      case "$TERM" in
        xterm*|rxvt*|screen*|tmux*|alacritty*|kitty*) ;;
        *) export TERM=xterm-256color ;;
      esac

      # Safer handling for restricted environments
      # Only enable restricted mode if bash is actually restricted
      if shopt -q restricted_shell 2>/dev/null; then
        # Restricted shell detected
        export BASH_RESTRICTED_MODE=1
      fi

      # VS Code specific handling for terminal compatibility
      if [[ -n "$VSCODE_INJECTION" ]] || [[ "$TERM_PROGRAM" == "vscode" ]]; then
        # VS Code terminal detected
        export VSCODE_TERMINAL=1
      fi

      # No need for additional shopt testing - the above check is sufficient

      # Simple prompt command for history
      export PROMPT_COMMAND='history -a; history -n'

      # Enhanced completion setup (Carapace handles most completions)
      if [[ -z "$BASH_RESTRICTED_MODE" ]]; then
        # Enable programmable completion if available
        if [[ -f /usr/share/bash-completion/bash_completion ]] || [[ -f /etc/bash_completion ]]; then
          # Source system bash completion
          for file in /usr/share/bash-completion/bash_completion /etc/bash_completion; do
            [[ -f "$file" ]] && source "$file" 2>/dev/null && break
          done
        fi

        # Source user-specific completions
        if [[ -f "$HOME/.config/bash/bash_completion" ]]; then
          source "$HOME/.config/bash/bash_completion"
        fi
      fi

      # Note: Ctrl+R history search is handled by Atuin (initialized later)
      # FZF shell integration provides Ctrl+T (files) and Alt+C (directories)

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

      # Set a proper fallback prompt before starship takes over
      # This prevents display issues if starship initialization is delayed
      export PS1='[\u@\h \W]\$ '

      # Blesh (Bash Line Editor) initialization
      # Enhanced bash line editing with syntax highlighting and auto-suggestions
      if [[ -z "$VSCODE_TERMINAL" ]] && [[ -z "$BASH_RESTRICTED_MODE" ]]; then
        # Check for blesh in multiple possible locations
        for blesh_path in "${pkgs.blesh}/share/blesh/ble.sh" "/usr/share/blesh/ble.sh" "/usr/local/share/blesh/ble.sh"; do
          if [[ -f "$blesh_path" ]]; then
            source "$blesh_path" --noattach 2>/dev/null || true
            if declare -f ble-attach &>/dev/null; then
              ble-attach 2>/dev/null || true
            fi
            break
          fi
        done
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
            kill|killall) fzf --preview 'ps -p {} -o pid,ppid,user,start,time,command 2>/dev/null || echo "Process not found"' --preview-window=up:3:wrap "$@" ;;
            *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
          esac
        }
      fi

      # Source common shell functions
      if [ -f "$HOME/.config/shell/functions.sh" ]; then
        source "$HOME/.config/shell/functions.sh"
      fi

      # Enhanced command not found handler
      command_not_found_handle() {
        local cmd="$1"

        # Try nix-locate first
        if command -v nix-locate &> /dev/null; then
          echo "Command '$cmd' not found. Searching in nixpkgs..." >&2
          nix-locate --top-level --minimal --at-root "/bin/$cmd" 2>/dev/null || true
        fi

        # Try to suggest similar commands
        if command -v fzf &> /dev/null && command -v compgen &> /dev/null; then
          echo "Did you mean one of these?" >&2
          compgen -c | fzf --height=10 --reverse --query="$cmd" --preview="which {}" 2>/dev/null || true
        fi

        echo "bash: $cmd: command not found" >&2
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

  # Create custom bash completion file
  home.file.".config/bash/bash_completion" = {
    text = ''
      # Custom bash completions

      # Git completion enhancements
      if command -v git &> /dev/null; then
        # Complete git branches with better formatting
        _git_branch_complete() {
          local cur="${COMP_WORDS[COMP_CWORD]}"
          COMPREPLY=($(git branch --format='%(refname:short)' 2>/dev/null | grep "^$cur" | head -20))
        }

        # Complete git remotes
        _git_remote_complete() {
          local cur="${COMP_WORDS[COMP_CWORD]}"
          COMPREPLY=($(git remote 2>/dev/null | grep "^$cur"))
        }

        # Complete git tags
        _git_tag_complete() {
          local cur="${COMP_WORDS[COMP_CWORD]}"
          COMPREPLY=($(git tag 2>/dev/null | grep "^$cur" | head -20))
        }
      fi

      # Docker completion enhancements
      if command -v docker &> /dev/null; then
        # Complete docker containers
        _docker_container_complete() {
          local cur="${COMP_WORDS[COMP_CWORD]}"
          COMPREPLY=($(docker ps --format "table {{.Names}}" 2>/dev/null | tail -n +2 | grep "^$cur"))
        }

        # Complete docker images
        _docker_image_complete() {
          local cur="${COMP_WORDS[COMP_CWORD]}"
          COMPREPLY=($(docker images --format "table {{.Repository}}:{{.Tag}}" 2>/dev/null | tail -n +2 | grep "^$cur"))
        }
      fi

      # Nix completion enhancements
      if command -v nix &> /dev/null; then
        # Complete nix flake inputs
        _nix_flake_input_complete() {
          local cur="${COMP_WORDS[COMP_CWORD]}"
          if [[ -f flake.nix ]] || [[ -f flake.lock ]]; then
            COMPREPLY=($(nix flake metadata --json 2>/dev/null | jq -r '.locks.nodes | keys[]' | grep "^$cur"))
          fi
        }
      fi

      # Custom completions for common commands
      complete -F _git_branch_complete git-checkout git-checkout
      complete -F _git_remote_complete git-push git-pull
      complete -F _git_tag_complete git-tag
      complete -F _docker_container_complete docker-exec docker-logs docker-stop
      complete -F _docker_image_complete docker-run docker-pull
      complete -F _nix_flake_input_complete nix-flake-update
    '';
    executable = false;
  };
}
