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
    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    enableVteIntegration = true;
    autocd = true;
    # defaultKeymap = "emacs";

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
      searchUpKey = [
        "^[[A"
        "^P"
      ];
      searchDownKey = [
        "^[[B"
        "^N"
      ];
    };

    # Shell options
    setOptions = [
      # AUTO_CD is enabled via autocd = true above
      "AUTO_PUSHD"
      "PUSHD_IGNORE_DUPS"
      "PUSHD_SILENT"
      "CORRECT"
      "CORRECT_ALL"
      "GLOB_COMPLETE"
      "EXTENDED_GLOB"
      "NO_CASE_GLOB"
      "MENU_COMPLETE"
      "LIST_PACKED"
      "COMPLETE_IN_WORD"
      "HIST_VERIFY"
      "HIST_REDUCE_BLANKS"
      "HIST_SAVE_NO_DUPS"
      "HIST_FIND_NO_DUPS"
      "INTERACTIVE_COMMENTS"
      "NO_BEEP"
      "PROMPT_SUBST"
    ];

    # ZSH-specific shell aliases
    shellAliases = {
      zshrc = "$EDITOR ~/.config/zsh/.zshrc";
      zshenv = "$EDITOR ~/.config/zsh/.zshenv";
      reload = "exec zsh";
    };

    # Global aliases
    shellGlobalAliases = {
      NUL = "> /dev/null 2>&1";
      # ERR removed: global alias "2>&1" can cause "Bad file descriptor" errors
      # Use explicit "2>&1" redirection instead
      JSON = "| jq '.'";
      XML = "| xmllint --format -";
      TABLE = "| column -t";
      COUNT = "| wc -l";
      SORT = "| sort";
      UNIQ = "| sort | uniq";
    };

    # Plugins (autosuggestions and history-substring-search are built-in)
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

    loginExtra = ''
      if [[ -o interactive ]] && [[ -t 0 ]] && command -v fastfetch &> /dev/null; then
        fastfetch
      fi
    '';

    logoutExtra = ''
      clear
    '';

    initContent = ''
      # Disable # as glob character for flake references (allows .#hostname without quotes)
      disable -p '#'

      # Enable vim mode
      bindkey -v


      # fzf-tab configuration
      zstyle ':fzf-tab:*' fzf-command fzf
      zstyle ':fzf-tab:*' fzf-pad 4
      zstyle ':fzf-tab:*' fzf-flags '--height=70%' '--layout=reverse' '--info=inline' '--border' '--preview-window=right:60%:wrap'
      zstyle ':fzf-tab:*' fzf-bindings 'tab:down' 'btab:up' 'ctrl-space:toggle' 'ctrl-a:toggle-all'
      zstyle ':fzf-tab:*' continuous-trigger '/'
      zstyle ':fzf-tab:*' prefix ""
      zstyle ':fzf-tab:*' show-group full
      zstyle ':fzf-tab:*' switch-group ',' '.'

      # Completion formatting
      zstyle ':fzf-tab:complete:*:*' fzf-preview 'echo ''${(Q)desc}'
      zstyle ':fzf-tab:complete:*:descriptions' format '[%d]'
      zstyle ':completion:*' list-separator $'\t'
      zstyle ':completion:*:*:*:*:descriptions' format '%F{yellow}-- %d --%f'
      zstyle ':completion:*:*:*:*:*' sort false
      zstyle ':completion:*' group-name ""

      # Systemctl completion preview
      zstyle ':fzf-tab:complete:systemctl*:*' fzf-preview '
        case "$group" in
          "systemd unit"|"systemd units")
            systemctl status "$word" 2>/dev/null | head -20
            ;;
          "systemd command"|"systemctl command"|"systemctl commands")
            echo "Command: $word"
            echo ""
            man systemctl 2>/dev/null | col -b | sed -n "/^[[:space:]]*$word/,/^[[:space:]]*[a-z]/p" | head -15
            ;;
          "options"|"option")
            local search_opt="''${word#--}"
            search_opt="''${search_opt#-}"
            if man systemctl 2>/dev/null | col -b | grep -A 5 -E "^[[:space:]]*(-[a-z], )?--$search_opt" | head -10; then
              :
            elif man systemctl 2>/dev/null | col -b | grep -A 3 "^[[:space:]]*$word" | head -5; then
              :
            else
              echo "Option: $word"
              echo ""
              echo "''${(Q)desc}"
            fi
            ;;
          *)
            echo "''${(Q)desc}"
            ;;
        esac
      '

      # General command option preview
      zstyle ':fzf-tab:complete:*:options' fzf-preview '
        local cmd="''${words[1]}"
        if [[ -n "$cmd" ]] && man "$cmd" 2>/dev/null | head -1 | grep -q .; then
          local search_opt="''${word#--}"
          search_opt="''${search_opt#-}"
          if man "$cmd" 2>/dev/null | col -b | grep -A 5 -E "^[[:space:]]*(-[a-z], )?--$search_opt" | head -10; then
            :
          elif man "$cmd" 2>/dev/null | col -b | grep -A 3 "^[[:space:]]*$word" | head -5; then
            :
          else
            echo "Option: $word"
            echo ""
            echo "''${(Q)desc}"
          fi
        else
          echo "Option: $word"
          [[ -n "$desc" ]] && echo "''${(Q)desc}"
        fi
      '

      show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat --style=numbers --color=always --line-range=:500 {}; fi"

      _fzf_comprun() {
        local command=$1
        shift

        case "$command" in
          cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
          export|unset) fzf --preview "eval 'echo \''${}'"         "$@" ;;
          ssh)          fzf --preview 'dig {}'                   "$@" ;;
          *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
        esac
      }

      # Source common shell functions
      if [ -f "$HOME/.config/shell/functions.sh" ]; then
        source "$HOME/.config/shell/functions.sh"
      fi
    '';
  };
}
