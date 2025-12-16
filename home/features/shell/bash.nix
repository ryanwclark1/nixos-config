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
    enableCompletion = true;
    enableVteIntegration = true;

    # History configuration
    historySize = 100000;
    historyFileSize = 100000;
    historyFile = "${config.home.homeDirectory}/.config/bash/history";

    shellOptions = [
      # History
      "histappend"
      "histverify"

      # Pathname expansion
      "cdspell"
      "dotglob"
      "extglob"
      "globstar"
      "nocaseglob"
      "nocasematch"

      # Job control
      "checkjobs"
      "huponexit"

      # Interactive behavior
      "autocd"
      "cdable_vars"
      "checkwinsize"
      "cmdhist"
      "lithist"

      # Error handling
      "inherit_errexit"
      "interactive_comments"
      "failglob"
      "nullglob"

      # Modern features
      "assoc_expand_once"
    ];

    # Bash-specific session variables
    sessionVariables = {
      BASH_INTERACTIVE = "${pkgs.bashInteractive}/bin/bash";
      BASH_COMPLETION_USER_FILE = "${config.home.homeDirectory}/.config/bash/bash_completion";
    };

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

      # VS Code terminal detection
      if [[ -n "$VSCODE_INJECTION" ]] || [[ "$TERM_PROGRAM" == "vscode" ]]; then
        export VSCODE_TERMINAL=1
      fi

      # History synchronization - use a function that starship can append to
      _bash_history_sync() {
        history -a
        history -n
      }
      export PROMPT_COMMAND='_bash_history_sync'

      # Bash completion setup
      if [[ -z "$BASH_RESTRICTED_MODE" ]]; then
        if [[ -f /usr/share/bash-completion/bash_completion ]] || [[ -f /etc/bash_completion ]]; then
          for file in /usr/share/bash-completion/bash_completion /etc/bash_completion; do
            [[ -f "$file" ]] && source "$file" 2>/dev/null && break
          done
        fi

        if [[ -f "$HOME/.config/bash/bash_completion" ]]; then
          source "$HOME/.config/bash/bash_completion"
        fi
      fi

      # Directory shortcuts (cdable_vars enabled in shellOptions)
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
      # Restricted shell handling
      if [[ -n "$BASH_RESTRICTED_MODE" ]]; then
        if [ -f "$HOME/.config/shell/functions.sh" ]; then
          source "$HOME/.config/shell/functions.sh"
        fi
        return
      fi

      # Fallback prompt (before starship initialization)
      export PS1='[\u@\h \W]\$ '

      # Blesh (Bash Line Editor) initialization
      if [[ -z "$VSCODE_TERMINAL" ]] && [[ -z "$BASH_RESTRICTED_MODE" ]]; then
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

      # FZF completion preview customization
      if command -v fzf &> /dev/null; then
        show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat --style=numbers --color=always --line-range=:500 {}; fi"

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

      # Command not found handler
      command_not_found_handle() {
        local cmd="$1"

        if command -v nix-locate &> /dev/null; then
          echo "Command '$cmd' not found. Searching in nixpkgs..." >&2
          nix-locate --top-level --minimal --at-root "/bin/$cmd" 2>/dev/null || true
        fi

        if command -v fzf &> /dev/null && command -v compgen &> /dev/null; then
          echo "Did you mean one of these?" >&2
          compgen -c | fzf --height=10 --reverse --query="$cmd" --preview="which {}" 2>/dev/null || true
        fi

        echo "bash: $cmd: command not found" >&2
        return 127
      }
    '';

    logoutExtra = ''
      clear
      history -a
    '';
  };

  # Custom bash completion file
  home.file.".config/bash/bash_completion" = {
    text = ''
      # Git completions
      if command -v git &> /dev/null; then
        _git_branch_complete() {
          local cur="$${COMP_WORDS[COMP_CWORD]}"
          COMPREPLY=($(git branch --format='%(refname:short)' 2>/dev/null | grep "^$cur" | head -20))
        }

        _git_remote_complete() {
          local cur="$${COMP_WORDS[COMP_CWORD]}"
          COMPREPLY=($(git remote 2>/dev/null | grep "^$cur"))
        }

        _git_tag_complete() {
          local cur="$${COMP_WORDS[COMP_CWORD]}"
          COMPREPLY=($(git tag 2>/dev/null | grep "^$cur" | head -20))
        }
      fi

      # Docker completions
      if command -v docker &> /dev/null; then
        _docker_container_complete() {
          local cur="$${COMP_WORDS[COMP_CWORD]}"
          COMPREPLY=($(docker ps --format "table {{.Names}}" 2>/dev/null | tail -n +2 | grep "^$cur"))
        }

        _docker_image_complete() {
          local cur="$${COMP_WORDS[COMP_CWORD]}"
          COMPREPLY=($(docker images --format "table {{.Repository}}:{{.Tag}}" 2>/dev/null | tail -n +2 | grep "^$cur"))
        }
      fi

      # Nix completions
      if command -v nix &> /dev/null; then
        _nix_flake_input_complete() {
          local cur="$${COMP_WORDS[COMP_CWORD]}"
          if [[ -f flake.nix ]] || [[ -f flake.lock ]]; then
            COMPREPLY=($(nix flake metadata --json 2>/dev/null | jq -r '.locks.nodes | keys[]' | grep "^$cur"))
          fi
        }
      fi

      # Register completions
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
