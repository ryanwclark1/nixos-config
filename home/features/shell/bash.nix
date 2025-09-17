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

    # Session variables - matching ZSH configuration
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less";
      LESS = "-R";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      BAT_THEME = "Catppuccin-frappe";
      BASH_INTERACTIVE = "${pkgs.bashInteractive}/bin/bash";
    };

    # Shell aliases - matching ZSH configuration
    shellAliases = {
      # Directory navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      "-" = "cd -";

      # Git shortcuts
      g = "git";
      ga = "git add";
      gc = "git commit";
      gca = "git commit -a";
      gcam = "git commit -am";
      gco = "git checkout";
      gd = "git diff";
      gds = "git diff --staged";
      gl = "git log --oneline --graph";
      gp = "git push";
      gpu = "git pull";
      gs = "git status -sb";
      gst = "git status";

      # System management
      rebuild = "sudo nixos-rebuild switch --flake .#$(hostname)";
      update = "nix flake update";
      upgrade = "nix flake update && sudo nixos-rebuild switch --flake .#$(hostname)";
      cleanup = "sudo nix-collect-garbage -d && nix store optimise";

      # Better defaults
      grep = "rg";
      find = "fd";
      ps = "procs";
      top = "btop";
      htop = "btop";
      du = "dust";
      df = "duf";
      # cat alias handled by bat module

      # Safety nets
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -I";

      # Shortcuts
      v = "nvim";
      vim = "nvim";
      vi = "nvim";
      e = "$EDITOR";
      o = "xdg-open";

      # Docker shortcuts
      d = "docker";
      dc = "docker compose";
      dps = "docker ps";
      dpsa = "docker ps -a";
      dimg = "docker images";
      drm = "docker rm";
      drmi = "docker rmi";

      # Systemctl shortcuts
      sc = "systemctl";
      scu = "systemctl --user";
      scs = "sudo systemctl";

      # Quick edits
      bashrc = "$EDITOR ~/.bashrc";
      nixconf = "$EDITOR ~/nixos-config/flake.nix";

      # Network
      ip = "ip --color=auto";
      ports = "ss -tulanp";

      # Misc
      h = "history";
      help = "man";
      # j/jj aliases not needed - zoxide replaces cd directly
      mk = "mkdir -p";
      path = "echo $PATH | tr ':' '\\n'";
      reload = "exec bash";
      tf = "terraform";
      k = "kubectl";
      kx = "kubectx";
      kns = "kubens";

      # Kitty specific
      cik = "clone-in-kitty --type os-window";
      ck = "clone-in-kitty --type os-window";
    };

    profileExtra = ''
      # Set up PATH
      export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:$PATH"

      # Set up XDG directories
      export XDG_CONFIG_HOME="$HOME/.config"
      export XDG_CACHE_HOME="$HOME/.cache"
      export XDG_DATA_HOME="$HOME/.local/share"
      export XDG_STATE_HOME="$HOME/.local/state"

      # LS_COLORS using vivid
      if command -v vivid &> /dev/null; then
        export LS_COLORS="$(vivid generate catppuccin-frappe)"
      fi
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

      # Bash-specific completion enhancements
      bind "set completion-ignore-case on"
      bind "set completion-map-case on"
      bind "set show-all-if-ambiguous on"
      bind "set mark-symlinked-directories on"
      bind "set colored-stats on"
      bind "set visible-stats on"
      bind "set page-completions off"
      bind "set menu-complete-display-prefix on"
      bind "set completion-query-items 200"

      # Better history search with arrow keys
      bind '"\e[A": history-search-backward'
      bind '"\e[B": history-search-forward'
      bind '"\e[C": forward-char'
      bind '"\e[D": backward-char'

      # Ctrl+R handled by atuin if available, fallback to fzf
      if ! command -v atuin &> /dev/null && command -v fzf &> /dev/null; then
        bind -x '"\C-r": __fzf_history'
        __fzf_history() {
          local output
          output=$(history | fzf --tac --no-sort --exact --query "$READLINE_LINE" | sed 's/^[ ]*[0-9]*[ ]*//')
          READLINE_LINE=$output
          READLINE_POINT=''${#READLINE_LINE}
        }
      fi

      # Directory shortcuts (similar to ZSH's hash -d)
      shopt -s cdable_vars 2>/dev/null || true
      export dl="$HOME/Downloads"
      export docs="$HOME/Documents"
      export dev="$HOME/Code"
      export nix="$HOME/nixos-config"
      export dots="$HOME/.config"

      # CDPATH for quick navigation
      export CDPATH=".:$HOME:$HOME/Code:$HOME/nixos-config"

      # Colorized man pages
      export LESS_TERMCAP_mb=$'\e[1;32m'
      export LESS_TERMCAP_md=$'\e[1;32m'
      export LESS_TERMCAP_me=$'\e[0m'
      export LESS_TERMCAP_se=$'\e[0m'
      export LESS_TERMCAP_so=$'\e[01;33m'
      export LESS_TERMCAP_ue=$'\e[0m'
      export LESS_TERMCAP_us=$'\e[1;4;31m'
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

      # Zoxide integration handled by zoxide module with --cmd cd

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

      # Directory functions
      mkcd() {
        mkdir -p "$1" && cd "$1"
      }

      # Archive extraction
      extract() {
        if [ -f "$1" ]; then
          case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }

      # Docker helper functions for non-interactive environments
      docker-exec() {
        local container="$1"
        shift
        if [ -t 0 ] && [ -t 1 ]; then
          docker exec -it "$container" "$@"
        else
          docker exec "$container" "$@"
        fi
      }

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

      # Git functions
      gclone() {
        git clone "$1" && cd "$(basename "''${1}" .git)"
      }

      # Quick backup function
      backup() {
        cp -r "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)"
      }

      # System information
      sysinfo() {
        echo "Hostname: $(hostname)"
        echo "Kernel: $(uname -r)"
        echo "Uptime: $(uptime -p)"
        echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
        echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2}')"
        echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
      }

      # Weather function
      weather() {
        curl -s "wttr.in/''${1:-}"
      }

      # Cheat sheet function
      cheat() {
        curl -s "cheat.sh/''${1}"
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
