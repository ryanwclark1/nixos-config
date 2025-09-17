{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.ion = {
    enable = true;
    package = pkgs.ion;
    
    # Ion shell initialization script
    initExtra = ''
      # Set environment variables
      export EDITOR=nvim
      export VISUAL=nvim
      export PAGER=less
      export LESS="-R"
      export MANPAGER="sh -c 'col -bx | bat -l man -p'"
      export BAT_THEME="Catppuccin-frappe"
      export TERM="xterm-256color"
      
      # FZF configuration handled by fzf module
      
      # Path configuration
      export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:$PATH"
      
      # XDG Base Directories
      export XDG_CONFIG_HOME="$HOME/.config"
      export XDG_CACHE_HOME="$HOME/.cache"
      export XDG_DATA_HOME="$HOME/.local/share"
      export XDG_STATE_HOME="$HOME/.local/state"
      
      # LS_COLORS using vivid if available
      if test -x $(which vivid)
        export LS_COLORS="$(vivid generate catppuccin-frappe)"
      end
      
      # Aliases - Directory navigation
      alias .. = cd ..
      alias ... = cd ../..
      alias .... = cd ../../..
      alias ..... = cd ../../../..
      alias - = cd -
      
      # Git shortcuts
      alias g = git
      alias ga = git add
      alias gc = git commit
      alias gca = git commit -a
      alias gcam = git commit -am
      alias gco = git checkout
      alias gd = git diff
      alias gds = git diff --staged
      alias gl = git log --oneline --graph
      alias gp = git push
      alias gpu = git pull
      alias gs = git status -sb
      alias gst = git status
      
      # System management
      alias rebuild = sudo nixos-rebuild switch --flake .#$(hostname)
      alias update = nix flake update
      alias upgrade = nix flake update && sudo nixos-rebuild switch --flake .#$(hostname)
      alias cleanup = sudo nix-collect-garbage -d && nix store optimise
      
      # Better defaults
      alias grep = rg
      alias find = fd
      alias ps = procs
      alias top = btop
      alias htop = btop
      alias du = dust
      alias df = duf
      # cat alias handled by bat module
      # ls aliases handled by eza module
      alias la = ls -a  # Will use eza's ls alias
      alias ll = ls -l  # Will use eza's ls alias
      
      # Safety nets
      alias cp = cp -i
      alias mv = mv -i
      alias rm = rm -I
      
      # Shortcuts
      alias v = nvim
      alias vim = nvim
      alias vi = nvim
      alias e = $EDITOR
      alias o = xdg-open
      
      # Docker shortcuts
      alias d = docker
      alias dc = docker compose
      alias dps = docker ps
      alias dpsa = docker ps -a
      alias dimg = docker images
      alias drm = docker rm
      alias drmi = docker rmi
      
      # Systemctl shortcuts
      alias sc = systemctl
      alias scu = systemctl --user
      alias scs = sudo systemctl
      
      # Quick edits
      alias bashrc = $EDITOR ~/.bashrc
      alias zshrc = $EDITOR ~/.zshrc
      alias ionrc = $EDITOR ~/.config/ion/initrc
      alias nixconf = $EDITOR ~/nixos-config/flake.nix
      
      # Network
      alias ip = ip --color=auto
      alias ports = ss -tulanp
      
      # Misc
      alias h = history
      alias help = man
      # j/jj aliases not needed - zoxide replaces cd directly
      alias mk = mkdir -p
      alias path = echo $PATH | tr ':' '\n'
      alias reload = exec ion
      alias tf = terraform
      alias k = kubectl
      alias kx = kubectx
      alias kns = kubens
      
      # Kitty specific
      alias cik = clone-in-kitty --type os-window
      alias ck = clone-in-kitty --type os-window
      
      # Functions for Ion shell
      
      # Directory creation and navigation
      fn mkcd dir
        mkdir -p $dir
        cd $dir
      end
      
      # Git clone and cd
      fn gclone repo
        git clone $repo
        let basename = $(basename $repo .git)
        cd $basename
      end
      
      # Archive extraction
      fn extract file
        if test -f $file
          case $file
            when *.tar.bz2
              tar xjf $file
            when *.tar.gz
              tar xzf $file
            when *.bz2
              bunzip2 $file
            when *.rar
              unrar e $file
            when *.gz
              gunzip $file
            when *.tar
              tar xf $file
            when *.tbz2
              tar xjf $file
            when *.tgz
              tar xzf $file
            when *.zip
              unzip $file
            when *.Z
              uncompress $file
            when *.7z
              7z x $file
            when *
              echo "'$file' cannot be extracted"
          end
        else
          echo "'$file' is not a valid file"
        end
      end
      
      # Quick backup
      fn backup file
        let timestamp = $(date +%Y%m%d_%H%M%S)
        cp -r $file "$file.bak.$timestamp"
      end
      
      # System information
      fn sysinfo
        echo "Hostname: $(hostname)"
        echo "Kernel: $(uname -r)"
        echo "Uptime: $(uptime -p)"
        echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
        echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2}')"
        echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
      end
      
      # Weather
      fn weather location
        if test -z $location
          curl -s "wttr.in/"
        else
          curl -s "wttr.in/$location"
        end
      end
      
      # Cheat sheet
      fn cheat topic
        curl -s "cheat.sh/$topic"
      end
      
      # Docker helper functions
      fn docker-exec container @args
        if test -t 0 && test -t 1
          docker exec -it $container @args
        else
          docker exec $container @args
        end
      end
      
      fn docker-bash container @args
        if test -t 0 && test -t 1
          docker exec -it $container bash @args
        else
          docker exec $container bash @args
        end
      end
      
      fn docker-sh container @args
        if test -t 0 && test -t 1
          docker exec -it $container sh @args
        else
          docker exec $container sh @args
        end
      end
      
      # Zoxide integration handled by zoxide module with --cmd cd
      
      # Display system info on login (only in interactive sessions)
      if test -t 0 && test -x $(which fastfetch)
        fastfetch
      end
      
      # History configuration
      export HISTFILE="$HOME/.config/ion/history"
      export HISTSIZE=100000
      export SAVEHIST=100000
      
      # Set prompt (Ion uses PS1)
      export PS1='$(if test $? -eq 0; echo "\[\033[01;32m\]✓"; else echo "\[\033[01;31m\]✗"; end) \[\033[01;34m\]\w\[\033[00m\] $(if test -d .git; echo "\[\033[01;33m\][$(git branch --show-current 2>/dev/null)]\[\033[00m\] "; end)> '
    '';
  };
  
  # Create Ion config directory
  home.file.".config/ion/.keep".text = "";
}