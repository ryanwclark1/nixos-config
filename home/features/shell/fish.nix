{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Catppuccin Frappe color palette
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
  # Catppuccin Frappe theme
  home.file.".config/fish/themes/frappe.theme" = {
    text = ''
      # name: 'Catppuccin Frappe Enhanced'
      # url: 'https://github.com/catppuccin/fish'
      # preferred_background: ${base00}

      # Basic syntax highlighting
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

      # Selection and search
      fish_color_selection --background=${base02}
      fish_color_search_match --background=${base02}

      # Advanced syntax
      fish_color_option ${base0B}
      fish_color_operator ${base17}
      fish_color_escape ${base12}
      fish_color_autosuggestion 737994
      fish_color_cancel ${base08}

      # Prompt colors
      fish_color_cwd ${base0A}
      fish_color_user ${base0C}
      fish_color_host ${base0D}
      fish_color_host_remote ${base0B}
      fish_color_status ${base08}

      # Pager colors
      fish_pager_color_progress 737994
      fish_pager_color_prefix ${base17}
      fish_pager_color_completion ${base05}
      fish_pager_color_description 737994
      fish_pager_color_selected_background --background=${base02}
      fish_pager_color_selected_prefix ${base17}
      fish_pager_color_selected_completion ${base05}
      fish_pager_color_selected_description 737994
    '';
  };

  programs.fish = {
    enable = true;
    package = pkgs.fish;
    preferAbbrs = true;
    generateCompletions = true;

    # Fish-specific shell aliases
    shellAliases = {
      clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
      reload = "exec fish";
      fishconfig = "$EDITOR ~/.config/fish/config.fish";
      fishfunc = "$EDITOR ~/.config/fish/functions/";
      history = "history | head -20";

    };

    # Shell abbreviations
    shellAbbrs = {
      # Git commands
      gcmsg = "git commit -m";
      gpsup = "git push --set-upstream origin (git branch --show-current)";
      grbi = "git rebase -i";
      grhh = "git reset --hard HEAD";
      gwip = "git add -A; git commit -m 'WIP'";
      gstash = "git stash";
      gpop = "git stash pop";
      gco = "git checkout";
      gcb = "git checkout -b";
      gcm = "git checkout main";
      gpu = "git pull";
      gp = "git push";



      # Docker shortcuts
      dps = "docker ps";
      dpsa = "docker ps -a";
      dimg = "docker images";
      drm = "docker rm";
      drmi = "docker rmi";
      dexec = "docker exec -it";

      # Kubernetes shortcuts
      k = "kubectl";
      kx = "kubectx";
      kns = "kubens";
      kgp = "kubectl get pods";
      kgs = "kubectl get services";
      kgd = "kubectl get deployments";
    };

    # Plugins
    plugins = [
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
      {
        name = "tide";
        src = pkgs.fishPlugins.tide.src;
      }
    ];

    # Functions
    functions = {
      mkcd = ''
        mkdir -p $argv[1] && cd $argv[1]
      '';

      up = ''
        for i in (seq 1 $argv[1])
          cd ..
        end
      '';

      gclone = ''
        git clone $argv[1] && cd (basename $argv[1] .git)
      '';

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



      docker-exec = ''
        set -l container $argv[1]
        set -e argv[1]
        if test -t 0 && test -t 1
          docker exec -it $container $argv
        else
          docker exec $container $argv
        end
      '';

      docker-bash = ''
        set -l container $argv[1]
        set -e argv[1]
        if test -t 0 && test -t 1
          docker exec -it $container bash $argv
        else
          docker exec $container bash $argv
        end
      '';

      docker-sh = ''
        set -l container $argv[1]
        set -e argv[1]
        if test -t 0 && test -t 1
          docker exec -it $container sh $argv
        else
          docker exec $container sh $argv
        end
      '';

      backup = ''
        cp -r $argv[1] "$argv[1].bak."(date +%Y%m%d_%H%M%S)
      '';

      weather = ''
        curl -s "wttr.in/$argv[1]"
      '';

      cheat = ''
        curl -s "cheat.sh/$argv[1]"
      '';

      ll = ''
        eza -la --color=always --group-directories-first
      '';

      la = ''
        eza -a --color=always --group-directories-first
      '';

      lt = ''
        eza --tree --color=always --level=2
      '';

      find = ''
        fd $argv
      '';

      grep = ''
        rg $argv
      '';

      ps = ''
        procs $argv
      '';

      du = ''
        dust $argv
      '';

      df = ''
        duf $argv
      '';

      ports = ''
        ss -tulanp
      '';

      jqless = ''
        jq -C | bat --pager 'less RF' --style=numbers --color=always
      '';

      mkdir = ''
        mkdir -p $argv
      '';
    };

    loginShellInit = ''
      if status is-interactive && command -v fastfetch >/dev/null
        fastfetch
      end

      if command -v zoxide >/dev/null
        zoxide init fish | source
      end
    '';

    interactiveShellInit = ''
      set -U fish_greeting

      # Key bindings
      bind \ee edit_command_buffer
      bind \e\[C forward-char
      bind \e\[A history-search-backward
      bind \e\[B history-search-forward
      bind \cf accept-autosuggestion
      bind \ck up-or-search
      bind \cj down-or-search
      bind \e\[1;5C forward-word
      bind \e\[1;5D backward-word
      bind \e\[H beginning-of-line
      bind \e\[F end-of-line
      bind \e\[3~ delete-char
      bind \e\[1;5A beginning-of-line
      bind \e\[1;5B end-of-line

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

      # Custom prompt (overridden by starship if available)
      function fish_prompt
        set -l git_branch (git branch --show-current 2>/dev/null)
        set -l git_status (git status --porcelain 2>/dev/null)

        if test -n "$git_branch"
          set -l git_color (test -n "$git_status" && echo "red" || echo "green")
          echo -n (set_color $git_color)"[$git_branch]"
        end

        echo -n (set_color blue)(prompt_pwd)(set_color normal)" > "
      end

      # Initialize tools
      if command -v starship >/dev/null
        starship init fish | source
      end

      if command -v direnv >/dev/null
        direnv hook fish | source
      end

      # Completion settings
      set -gx FISH_COMPLETE_DIR_EXPAND 1
      set -gx FISH_COMPLETE_DIR_EXPAND_STRATEGY "descend"
      set -gx FISH_COMPLETE_DIR_EXPAND_STRATEGY_DESCEND_DEPTH 1

      # History settings
      set -gx FISH_HISTORY_FILE_SIZE 1000000
      set -gx FISH_HISTORY_MAX_COMMANDS 10000
    '';
  };
}
