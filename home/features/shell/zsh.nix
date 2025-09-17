{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.zsh = {
    enable = true;
    package = pkgs.zsh;
    enableCompletion = true;
    enableVteIntegration = true;
    autocd = true;  # Automatically cd into directory by typing its name
    defaultKeymap = "emacs";  # Can be "emacs" or "vicmd" for vi mode

    # Directory shortcuts
    dirHashes = {
      dl = "$HOME/Downloads";
      docs = "$HOME/Documents";
      dev = "$HOME/Code";
      nix = "$HOME/nixos-config";
      dots = "$HOME/.config";
    };

    # Search paths for cd command
    cdpath = [
      "$HOME"
      "$HOME/Code"
      "$HOME/nixos-config"
    ];

    # History configuration
    history = {
      size = 100000;
      save = 100000;
      path = "${config.home.homeDirectory}/.config/zsh/history";
      extended = true;  # Save timestamps
      ignoreDups = true;  # Don't save duplicates
      ignoreSpace = true;  # Don't save commands starting with space
      ignorePatterns = [
        "rm *"
        "pkill *"
        "kill *"
        "history *"
      ];
      share = true;  # Share history between sessions
      expireDuplicatesFirst = true;
    };

    # Syntax highlighting configuration
    syntaxHighlighting = {
      enable = true;
      highlighters = [
        "main"
        "brackets"
        "pattern"
        "cursor"
        "regexp"
        "root"
        "line"
      ];
      patterns = {
        "rm -rf *" = "fg=red,bold,underline";
        "sudo *" = "fg=yellow,bold";
      };
      styles = {
        comment = "fg=245";
        alias = "fg=cyan,bold";
        builtin = "fg=green,bold";
        command = "fg=blue,bold";
        function = "fg=magenta,bold";
        path = "fg=cyan,underline";
        globbing = "fg=yellow";
      };
    };

    # Auto-suggestions configuration
    autosuggestion = {
      enable = true;
      highlight = "fg=245";
      strategy = [
        "history"
        "completion"
        "match_prev_cmd"
      ];
    };

    # History substring search
    historySubstringSearch = {
      enable = true;
      searchUpKey = [ "^[[A" "^P" ];  # Up arrow and Ctrl+P
      searchDownKey = [ "^[[B" "^N" ];  # Down arrow and Ctrl+N
    };

    # Shell options
    setOptions = [
      "AUTO_CD"              # cd by typing directory name
      "AUTO_PUSHD"           # Make cd push directories onto stack
      "PUSHD_IGNORE_DUPS"    # Don't push duplicates
      "PUSHD_SILENT"         # Don't print directory stack
      "CORRECT"              # Command correction
      "CORRECT_ALL"          # Argument correction
      "GLOB_COMPLETE"        # Generate glob matches as completions
      "EXTENDED_GLOB"        # Extended globbing
      "NO_CASE_GLOB"         # Case insensitive globbing
      "MENU_COMPLETE"        # Cycle through completions
      "LIST_PACKED"          # Compact completion lists
      "COMPLETE_IN_WORD"     # Complete from cursor position
      "HIST_VERIFY"          # Reload line into buffer on history expansion
      "HIST_REDUCE_BLANKS"   # Remove superfluous blanks
      "HIST_SAVE_NO_DUPS"    # Don't save duplicates
      "HIST_FIND_NO_DUPS"    # Don't show duplicates in search
      "INTERACTIVE_COMMENTS" # Allow comments in interactive shell
      "NO_BEEP"             # Don't beep
      "PROMPT_SUBST"        # Parameter expansion in prompts
    ];

    # Shell aliases
    shellAliases = {
      # Directory navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      "-" = "cd -";

      # Enhanced ls (handled by eza module)

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

      # Better defaults (cat alias handled by bat module)
      grep = "rg";
      find = "fd";
      ps = "procs";
      top = "btop";
      htop = "btop";
      du = "dust";
      df = "duf";

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
      zshrc = "$EDITOR ~/.config/zsh/.zshrc";
      zshenv = "$EDITOR ~/.config/zsh/.zshenv";
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
      reload = "exec zsh";
      tf = "terraform";
      k = "kubectl";
      kx = "kubectx";
      kns = "kubens";
    };

    # Global aliases (can be used anywhere in command)
    shellGlobalAliases = {
      "--help" = "--help 2>&1 | bat --language=help --style=plain";
      "......" = "../../../../..";
      G = "| grep";
      L = "| less";
      H = "| head";
      T = "| tail";
      NUL = "> /dev/null 2>&1";
      ERR = "2>&1";
      JSON = "| jq '.'";
      XML = "| xmllint --format -";
      TABLE = "| column -t";
      COUNT = "| wc -l";
      SORT = "| sort";
      UNIQ = "| sort | uniq";
    };

    # Session variables
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less";
      LESS = "-R";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      BAT_THEME = "Catppuccin-frappe";
    };

    # Local variables (set at top of .zshrc)
    localVariables = {
      TERM = "xterm-256color";
      LS_COLORS = "$(${pkgs.vivid}/bin/vivid generate catppuccin-frappe)";
    };

    # Plugins
    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "master";
          sha256 = "sha256-gvZp8P3quOtcy1Xtt1LAW1cfZ/zCtnAmnWqcwrKel6w=";
        };
      }
      {
        name = "fast-syntax-highlighting";
        src = pkgs.fetchFromGitHub {
          owner = "zdharma-continuum";
          repo = "fast-syntax-highlighting";
          rev = "master";
          sha256 = "sha256-ZihUL4JAVk9V+IELSakytlb24BvEEJ161CQEHZYYoSA=";
        };
      }
      {
        name = "zsh-nix-shell";
        file = "nix-shell.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "chisui";
          repo = "zsh-nix-shell";
          rev = "master";
          sha256 = "sha256-IT3wpfw8zhiNQsrw59lbSWYh0NQ1CUdUtFzRzHlURH0=";
        };
      }
      {
        name = "you-should-use";
        src = pkgs.fetchFromGitHub {
          owner = "MichaelAquilina";
          repo = "zsh-you-should-use";
          rev = "master";
          sha256 = "sha256-u3abhv9ewq3m4QsnsxT017xdlPm3dYq5dqHNmQhhcpI=";
        };
      }
    ];

    # Completion initialization
    completionInit = ''
      # Initialize completion system
      autoload -Uz compinit && compinit
      autoload -Uz bashcompinit && bashcompinit

      # Completion options
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' menu select
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*:descriptions' format '%F{cyan}-- %d --%f'
      zstyle ':completion:*:messages' format '%F{yellow}-- %d --%f'
      zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path ~/.config/zsh/cache

      # Fuzzy completion
      zstyle ':completion:*' completer _complete _match _approximate
      zstyle ':completion:*:match:*' original only
      zstyle ':completion:*:approximate:*' max-errors 2

      # fzf-tab configuration
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
      zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
    '';

    # Extra environment configuration
    envExtra = ''
      # Set up PATH
      export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:$PATH"

      # Set up fzf
      if [[ ! "$PATH" == *${pkgs.fzf}/bin* ]]; then
        export PATH="${pkgs.fzf}/bin:$PATH"
      fi
    '';

    # Profile extra (sourced before .zshrc)
    # profileExtra = ''
    #   # Set up XDG directories
    #   export XDG_CONFIG_HOME="$HOME/.config"
    #   export XDG_CACHE_HOME="$HOME/.cache"
    #   export XDG_DATA_HOME="$HOME/.local/share"
    #   export XDG_STATE_HOME="$HOME/.local/state"
    # '';

    # Login extra
    loginExtra = ''
      # Display system info on login (only in interactive sessions)
      if [[ -o interactive ]] && [[ -t 0 ]] && command -v fastfetch &> /dev/null; then
        fastfetch
      fi
    '';

    # Logout extra
    logoutExtra = ''
      # Clear screen on logout
      clear
    '';

    # Init content (main zsh configuration)
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

    # Zoxide integration is handled by the zoxide module with --cmd cd
    # The module properly handles the cd command replacement

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
