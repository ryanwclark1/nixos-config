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
      MANPAGER = lib.mkDefault "sh -c 'col -bx | bat -l man -p'";
      MANROFFOPT = lib.mkDefault "-c";
      
      # Theme settings
      BAT_THEME = lib.mkDefault "Catppuccin-frappe";
      
      # XDG Base Directory Specification
      XDG_CONFIG_HOME = lib.mkDefault "$HOME/.config";
      XDG_CACHE_HOME = lib.mkDefault "$HOME/.cache";
      XDG_DATA_HOME = lib.mkDefault "$HOME/.local/share";
      XDG_STATE_HOME = lib.mkDefault "$HOME/.local/state";
      
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
    };
    
    # Session path additions
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.cargo/bin"
      "$HOME/go/bin"
    ];
    
    # Common shell aliases for all shells
    shellAliases = rec {
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
      
      # Better defaults (modern replacements)
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
      
      # Editor shortcuts
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
      k = "kubectl";
      kx = "kubectx";
      kns = "kubens";
      
      # JSON processing
      jqless = "jq -C | bat --pager 'less RF' --style=numbers --color=always";
      
      # Network management
      wifi = "nmtui";
      
      # Kitty specific (conditionally applied)
      cik = lib.mkIf config.programs.kitty.enable "clone-in-kitty --type os-window";
      ck = cik;
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
    
    # File management
    fzf           # Fuzzy finder
    zoxide        # Smart cd
    direnv        # Directory-specific environments
    vivid         # LS_COLORS generator
    
    # Archive tools
    unzip
    p7zip
    unrar
    
    # Network tools
    curl
    wget
    dig
    nmap
    
    # System tools
    tldr          # Simplified man pages
    which
    file
    tree
    
    # Development tools
    jq            # JSON processor
    yq            # YAML processor
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
      
      # Weather function
      weather() {
        curl -s "wttr.in/''${1:-}"
      }
      
      # Cheat sheet function
      cheat() {
        curl -s "cheat.sh/''${1}"
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