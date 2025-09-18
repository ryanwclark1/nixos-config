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
      # Ion-specific environment variables (most are in common.nix)
      # TERM is set in common.nix as COLORTERM

      # Ion-specific aliases (inherits from common.nix)
      alias ionrc = $EDITOR ~/.config/ion/initrc
      alias reload = exec ion

      # Functions for Ion shell

      # Source common shell functions if available
      # Note: Ion has different syntax, so we define Ion-specific versions

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

      # History configuration (ion uses Ion's internal history system)
      export HISTFILE="$HOME/.config/ion/history"

      # Set prompt (Ion uses PS1)
      export PS1='$(if test $? -eq 0; echo "\[\033[01;32m\]✓"; else echo "\[\033[01;31m\]✗"; end) \[\033[01;34m\]\w\[\033[00m\] $(if test -d .git; echo "\[\033[01;33m\][$(git branch --show-current 2>/dev/null)]\[\033[00m\] "; end)> '
    '';
  };

  # Create Ion config directory
  home.file.".config/ion/.keep".text = "";
}
