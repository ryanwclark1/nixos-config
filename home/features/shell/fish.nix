{
  config,
  pkgs,
  lib,
  ...
}:
let
  base00 = "303446"; # base
  base01 = "292c3c"; # mantle
  base02 = "414559"; # surface0
  base03 = "51576d"; # surface1
  base04 = "626880"; # surface2
  base05 = "c6d0f5"; # text
  base06 = "f2d5cf"; # rosewater
  base07 = "babbf1"; # lavender
  base08 = "e78284"; # red
  base09 = "ef9f76"; # peach
  base0A = "e5c890"; # yellow
  base0B = "a6d189"; # green
  base0C = "81c8be"; # teal
  base0D = "8caaee"; # blue
  base0E = "ca9ee6"; # mauve
  base0F = "eebebe"; # flamingo
  base10 = "292c3c"; # mantle - darker background
  base11 = "232634"; # crust - darkest background
  base12 = "ea999c"; # maroon - bright red
  base13 = "f2d5cf"; # rosewater - bright yellow
  base14 = "a6d189"; # green - bright green
  base15 = "99d1db"; # sky - bright cyan
  base16 = "85c1dc"; # sapphire - bright blue
  base17 = "f4b8e4"; # pink - bright purple
in

{
  home.file.".config/fish/themes/frappe.theme" = {
    text = ''
      # name: 'Catppuccin Frappe'
      # url: 'https://github.com/catppuccin/fish'
      # preferred_background: ${base00}

      fish_color_normal ${base05}
      fish_color_command ${base0D}
      fish_color_param ${base0F}
      fish_color_keyword ${base08}
      fish_color_quote ${base0B}
      fish_color_redirection ${base17}
      fish_color_end ${base09}
      fish_color_comment 838ba7
      fish_color_error ${base08}
      fish_color_gray 737994
      fish_color_selection --background=${base02}
      fish_color_search_match --background=${base02}
      fish_color_option ${base0B}
      fish_color_operator ${base17}
      fish_color_escape ${base12}
      fish_color_autosuggestion 737994
      fish_color_cancel ${base08}
      fish_color_cwd ${base0A}
      fish_color_user ${base0C}
      fish_color_host ${base0D}
      fish_color_host_remote ${base0B}
      fish_color_status ${base08}
      fish_pager_color_progress 737994
      fish_pager_color_prefix ${base17}
      fish_pager_color_completion ${base05}
      fish_pager_color_description 737994
    '';
  };

  programs.fish = {
    enable = true;
    package = pkgs.fish;

    # Use abbreviations for better auto-expansion
    preferAbbrs = true;

    # Fish-specific shell aliases (inherits from common.nix)
    shellAliases = {
      # Clear screen and scrollback (Fish-specific)
      clear = "printf '\\033[2J\\033[3J\\033[1;1H'";

      # Fish-specific reload
      reload = "exec fish";
    };

    # Shell abbreviations for expansion
    shellAbbrs = {
      # Expanded git commands
      gcmsg = "git commit -m";
      gpsup = "git push --set-upstream origin (git branch --show-current)";
      grbi = "git rebase -i";
      grhh = "git reset --hard HEAD";
      gwip = "git add -A; git commit -m 'WIP'";

      # Nix shortcuts
      nrs = "nix run nixpkgs#";
      nsh = "nix shell nixpkgs#";
      ndev = "nix develop";
      nbuild = "nix build";

      # Quick directory access (Fish-specific syntax)
      dl = "cd ~/Downloads";
      docs = "cd ~/Documents";
      dev = "cd ~/Code";
      nix = "cd ~/nixos-config";
      dots = "cd ~/.config";
    };

    # Plugins configuration
    plugins = [
      # TODO: Determine interaction between zoxide and z plugin
      # {
      #   name = "z";
      #   src = pkgs.fishPlugins.z.src;
      # }
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair.src;
      }
      {
        name = "sponge";
        src = pkgs.fishPlugins.sponge.src;
      }
    ];

    # Functions
    functions = {
      # Directory functions
      mkcd = ''
        mkdir -p $argv[1] && cd $argv[1]
      '';

      # Git functions
      gclone = ''
        git clone $argv[1] && cd (basename $argv[1] .git)
      '';

      # Archive extraction
      extract = ''
        if test -f $argv[1]
          switch $argv[1]
            case "*.tar.bz2"
              tar xjf $argv[1]
            case "*.tar.gz"
              tar xzf $argv[1]
            case "*.bz2"
              bunzip2 $argv[1]
            case "*.rar"
              unrar e $argv[1]
            case "*.gz"
              gunzip $argv[1]
            case "*.tar"
              tar xf $argv[1]
            case "*.tbz2"
              tar xjf $argv[1]
            case "*.tgz"
              tar xzf $argv[1]
            case "*.zip"
              unzip $argv[1]
            case "*.Z"
              uncompress $argv[1]
            case "*.7z"
              7z x $argv[1]
            case '*'
              echo "'$argv[1]' cannot be extracted"
          end
        else
          echo "'$argv[1]' is not a valid file"
        end
      '';

      # System info
      sysinfo = ''
        echo "Hostname: "(hostname)
        echo "Kernel: "(uname -r)
        echo "Uptime: "(uptime -p)
        echo "Memory: "(free -h | awk '/^Mem:/ {print $3 "/" $2}')
        echo "Disk: "(df -h / | awk 'NR==2 {print $3 "/" $2}')
        echo "Load: "(uptime | awk -F'load average:' '{print $2}')
      '';

      # Docker helpers
      docker-exec = ''
        set -l container $argv[1]
        set -e argv[1]
        if test -t 0 && test -t 1
          docker exec -it $container $argv
        else
          docker exec $container $argv
        end
      '';

      # Quick backup
      backup = ''
        cp -r $argv[1] "$argv[1].bak."(date +%Y%m%d_%H%M%S)
      '';

      # Weather
      weather = ''
        curl -s "wttr.in/$argv[1]"
      '';

      # Cheat sheet
      cheat = ''
        curl -s "cheat.sh/$argv[1]"
      '';
    };

    # Shell initialization (Fish-specific environment variables)
    shellInit = ''
      # Terminal
      set -gx TERM xterm-256color
    '';

    # Login shell initialization
    loginShellInit = ''
      # Display system info on login (only in interactive sessions)
      if status is-interactive && command -v fastfetch >/dev/null
        fastfetch
      end
    '';

    # Interactive shell initialization
    interactiveShellInit = ''
      # Remove fish greeting
      set -U fish_greeting

      # Key bindings
      bind \ee edit_command_buffer
      bind \e\[C forward-char  # Right arrow accepts autosuggestion
      bind \e\[A history-search-backward  # Up arrow
      bind \e\[B history-search-forward   # Down arrow
      bind \cf accept-autosuggestion  # Ctrl+F also accepts autosuggestion
      bind \ck up-or-search  # Ctrl+K for up
      bind \cj down-or-search  # Ctrl+J for down

      # Vi mode indicator
      function fish_mode_prompt
        switch $fish_bind_mode
          case default
            echo -n "(N) "
          case insert
            echo -n "(I) "
          case replace_one
            echo -n "(R) "
          case visual
            echo -n "(V) "
        end
      end

      # Zoxide integration handled by zoxide module with --cmd cd

      # Initialize starship prompt if available
      if command -v starship >/dev/null
        starship init fish | source
      end

      # Set up direnv hook if available
      if command -v direnv >/dev/null
        direnv hook fish | source
      end

      # Colored man pages (Fish-specific syntax)
      set -gx LESS_TERMCAP_mb (printf '\e[1;32m')
      set -gx LESS_TERMCAP_md (printf '\e[1;32m')
      set -gx LESS_TERMCAP_me (printf '\e[0m')
      set -gx LESS_TERMCAP_se (printf '\e[0m')
      set -gx LESS_TERMCAP_so (printf '\e[01;33m')
      set -gx LESS_TERMCAP_ue (printf '\e[0m')
      set -gx LESS_TERMCAP_us (printf '\e[1;4;31m')
    '';
  };
}
