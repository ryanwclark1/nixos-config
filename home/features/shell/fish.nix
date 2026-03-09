{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Catppuccin Frappe color palette
  colors = {
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
  };
in

{
  # Catppuccin Frappe theme
  home.file.".config/fish/themes/frappe.theme" = {
    text = ''
      # name: 'Catppuccin Frappe Enhanced'
      # url: 'https://github.com/catppuccin/fish'
      # preferred_background: ${colors.base00}

      # Basic syntax highlighting
      fish_color_normal ${colors.base05}
      fish_color_command ${colors.base0D}
      fish_color_param ${colors.base0F}
      fish_color_keyword ${colors.base08}
      fish_color_quote ${colors.base0B}
      fish_color_redirection ${colors.base17}
      fish_color_end ${colors.base09}
      fish_color_comment 838ba7
      fish_color_error ${colors.base08}
      fish_color_gray 737994

      # Selection and search
      fish_color_selection --background=${colors.base02}
      fish_color_search_match --background=${colors.base02}

      # Advanced syntax
      fish_color_option ${colors.base0B}
      fish_color_operator ${colors.base17}
      fish_color_escape ${colors.base12}
      fish_color_autosuggestion 737994
      fish_color_cancel ${colors.base08}

      # Prompt colors
      fish_color_cwd ${colors.base0A}
      fish_color_user ${colors.base0C}
      fish_color_host ${colors.base0D}
      fish_color_host_remote ${colors.base0B}
      fish_color_status ${colors.base08}

      # Pager colors
      fish_pager_color_progress 737994
      fish_pager_color_prefix ${colors.base17}
      fish_pager_color_completion ${colors.base05}
      fish_pager_color_description 737994
      fish_pager_color_selected_background --background=${colors.base02}
      fish_pager_color_selected_prefix ${colors.base17}
      fish_pager_color_selected_completion ${colors.base05}
      fish_pager_color_selected_description 737994
    '';
  };

  programs.fish = {
    enable = true;
    package = pkgs.fish;
    preferAbbrs = true;
    generateCompletions = true;

    # Fish-specific shell aliases (common aliases are in common.nix)
    shellAliases = {
      clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
      reload = "exec fish";
      fishconfig = "$EDITOR ~/.config/fish/config.fish";
      fishfunc = "$EDITOR ~/.config/fish/functions/";
      history = "history | head -20";
    };

    # Shell abbreviations (fish-specific feature)
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

    # Fish-specific functions (common functions are in common.nix)
    functions = {
      # Wrapper for cd to handle paths starting with '-'
      cd = ''
        if test (count $argv) -eq 0
          builtin cd
        else if string match -q -- '-*' $argv[1]
          # Path starts with '-', use '--' to prevent option parsing
          builtin cd -- $argv
        else
          builtin cd $argv
        end
      '';

      mkcd = ''
        mkdir -p $argv[1] && cd $argv[1]
      '';

      gclone = ''
        git clone $argv[1] && cd (basename $argv[1] .git)
      '';

      mkdir = ''
        command mkdir -p $argv
      '';
    };

    loginShellInit = ''
      if status is-interactive && command -v fastfetch >/dev/null
        fastfetch
      end
    '';

    interactiveShellInit = ''
      set -U fish_greeting

      # Key bindings
      bind \ee edit_command_buffer
      bind \e\[C forward-char
      bind \er _atuin_search
      bind -M insert \er _atuin_search
      bind \e\[A history-search-backward
      bind \e\[B history-search-forward
      bind \cf accept-autosuggestion
      bind \ck up-or-search
      bind \cj down-or-search
      bind \e\[H beginning-of-line
      bind \e\[F end-of-line
      bind \e\[3~ delete-char

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

      # Initialize tools
      if command -v starship >/dev/null
        starship init fish | source
      end

      if command -v direnv >/dev/null
        direnv hook fish | source
      end

      # Initialize fnm (Fast Node Manager)
      if command -v fnm >/dev/null
        fnm env --use-on-cd --shell fish | source
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
