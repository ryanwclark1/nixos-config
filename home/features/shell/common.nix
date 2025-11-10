{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Common shell configuration shared across all shells
  home = {
    # Common session variables for all shells
    sessionVariables = {
      # Editor settings
      EDITOR = lib.mkDefault "nvim";
      VISUAL = lib.mkDefault "nvim";

      # Pager settings
      PAGER = lib.mkDefault "less";
      LESS = lib.mkDefault "-R";
      LESSOPEN = lib.mkDefault "|${pkgs.bat-extras.batpipe}/bin/batpipe %s";
      BATPIPE = lib.mkDefault "color";
      MANPAGER = lib.mkDefault "sh -c 'col -bx | bat -l man -p'";
      MANROFFOPT = lib.mkDefault "-c";

      # Theme settings
      BAT_THEME = lib.mkDefault "theme";

      # XDG Base Directory Specification
      XDG_CONFIG_HOME = lib.mkDefault "$HOME/.config";
      XDG_CACHE_HOME = lib.mkDefault "$HOME/.cache";
      XDG_DATA_HOME = lib.mkDefault "$HOME/.local/share";
      XDG_STATE_HOME = lib.mkDefault "$HOME/.local/state";

      # History control (common across all shells)
      HISTCONTROL = lib.mkDefault "ignoreboth:erasedups";
      HISTTIMEFORMAT = lib.mkDefault "%F %T ";

      # Terminal capabilities
      COLORTERM = lib.mkDefault "truecolor";

      # Colored man pages
      LESS_TERMCAP_mb = lib.mkDefault "$(printf '\e[1;32m')";
      LESS_TERMCAP_md = lib.mkDefault "$(printf '\e[1;32m')";
      LESS_TERMCAP_me = lib.mkDefault "$(printf '\e[0m')";
      LESS_TERMCAP_se = lib.mkDefault "$(printf '\e[0m')";
      LESS_TERMCAP_so = lib.mkDefault "$(printf '\e[01;33m')";
      LESS_TERMCAP_ue = lib.mkDefault "$(printf '\e[0m')";
      LESS_TERMCAP_us = lib.mkDefault "$(printf '\e[1;4;31m')";

      # Development
      CDPATH = lib.mkDefault ".:$HOME:$HOME/Code:$HOME/nixos-config";

      # Enhanced shell experience
      SHELL_SESSION_ID = lib.mkDefault "$(date +%s)";
      HISTSIZE = lib.mkDefault "100000";
      SAVEHIST = lib.mkDefault "100000";

      # Better terminal experience
      TERM_PROGRAM = lib.mkDefault "unknown";
      TERM_PROGRAM_VERSION = lib.mkDefault "unknown";

      # Development environment indicators
      NIX_SHELL = lib.mkDefault "";
      IN_NIX_SHELL = lib.mkDefault "";

      # Performance optimizations
      # FZF environment variables are handled by programs.fzf module

      # Better man page experience
      MANWIDTH = lib.mkDefault "80";
      MANOPT = lib.mkDefault "--no-hyphenation --no-justification";
    };

    # Session path additions
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.cargo/bin"
      "$HOME/go/bin"
    ];

    # Common shell aliases for all shells
    shellAliases = rec {

      # Additional ls aliases for compatibility
      la = "ls -a";  # Will use eza's ls alias
      ll = "ls -l";  # Will use eza's ls alias

      # Better defaults (modern replacements)
      grep = "rg";
      find = "fd";
      ps = "procs";
      du = "dust";
      df = "duf";

      # Safety nets
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -I";

      # Editor shortcuts
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

      # Quick config edits
      nixconf = "$EDITOR ~/nixos-config/flake.nix";

      # Network
      ip = "ip --color=auto";
      ports = "ss -tulanp";

      # Misc utilities
      h = "history";
      help = "man";
      mk = "mkdir -p";
      path = "echo $PATH | tr ':' '\\n'";
      tf = "terraform";

      # Kubernetes shortcuts (consolidated from kubernetes/default.nix)
      k = "kubectl";
      kx = "kubectx";
      kns = "kubens";
      kgp = "kubectl get pods";
      kgs = "kubectl get services";
      kgd = "kubectl get deployments";
      kgn = "kubectl get nodes";
      kctx = "kubectx";
      kustomize-build = "kustomize build";

      # JSON processing
      jqless = "jq -C | bat --pager 'less RF' --style=numbers --color=always";

      # Network management
      wifi = "nmtui";

      # Kitty specific (conditionally applied)
      cik = lib.mkIf config.programs.kitty.enable "clone-in-kitty --type os-window";
    };

  };

  # Common packages for shell utilities
  home.packages = with pkgs; [
    # Modern CLI tools
    ripgrep       # Better grep
    fd            # Better find
    eza           # Better ls
    bat           # Better cat
    procs         # Better ps
    btop          # Better top
    dust          # Better du
    duf           # Better df
    delta         # Better diff
    hyperfine     # Benchmarking tool
    bottom        # Alternative to htop/btop
    gitui         # Terminal UI for git
    lazygit       # Another git UI
    neofetch      # System info display
    onefetch      # Git repository info

    # File management
    fzf           # Fuzzy finder
    zoxide        # Smart cd
    direnv        # Directory-specific environments

    # Archive tools
    unzip
    p7zip
    # unrar is provided by rar package in compression/default.nix

    # Network tools
    curl
    wget
    # dig is provided by dnsutils in networking-utils
    # nmap is provided in networking-utils

    # System tools     # Simplified man pages
    which
    file
    tree

    # Development tools
    jq            # JSON processor
    # yq is provided by yq-go in cli/default.nix (Go version is more feature-complete)
    xmlstarlet    # XML processor
  ];

  # Common shell functions (to be sourced by individual shells)
  home.file.".config/shell/functions.sh" = {
    text = ''
      # Directory functions
      mkcd() {
        mkdir -p "$1" && cd "$1"
      }

      # Git clone and cd
      gclone() {
        git clone "$1" && cd "$(basename "''${1}" .git)"
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

      # Weather function with better error handling
      weather() {
        local location="''${1:-}"
        if command -v curl >/dev/null 2>&1; then
          curl -s "wttr.in/$location" || echo "Failed to fetch weather data"
        else
          echo "curl not available for weather lookup"
        fi
      }

      # Cheat sheet function with better error handling
      cheat() {
        local topic="''${1:-}"
        if command -v curl >/dev/null 2>&1; then
          curl -s "cheat.sh/$topic" || echo "Failed to fetch cheat sheet"
        else
          echo "curl not available for cheat sheet lookup"
        fi
      }

      # Enhanced directory navigation
      up() {
        local levels="''${1:-1}"
        for ((i=1; i<=levels; i++)); do
          cd ..
        done
      }

      # Quick file operations
      mkdir-cd() {
        mkdir -p "$1" && cd "$1"
      }

      # Enhanced git functions
      git-branch-name() {
        git branch --show-current 2>/dev/null || echo "not-a-git-repo"
      }

      git-status-check() {
        if git rev-parse --git-dir >/dev/null 2>&1; then
          local status=$(git status --porcelain 2>/dev/null | wc -l)
          if [ "$status" -gt 0 ]; then
            echo "⚠️  $status uncommitted changes"
          else
            echo "✅ clean working tree"
          fi
        fi
      }

      # Enhanced system monitoring
      disk-usage() {
        if command -v dust >/dev/null 2>&1; then
          dust "$@"
        else
          du -h "$@" | sort -hr | head -20
        fi
      }

      # Process management
      kill-port() {
        local port="$1"
        if [ -z "$port" ]; then
          echo "Usage: kill-port <port>"
          return 1
        fi
        local pid=$(lsof -ti:$port)
        if [ -n "$pid" ]; then
          kill -9 "$pid"
          echo "Killed process $pid on port $port"
        else
          echo "No process found on port $port"
        fi
      }

      # FZF preview helper
      fzf-preview() {
        if [ -d "$1" ]; then
          eza --tree --color=always "$1" | head -200
        else
          bat --style=numbers --color=always --line-range=:500 "$1"
        fi
      }
    '';
    executable = false;
  };
}
