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

    # Use XDG config directory for ZSH files
    dotDir = "${config.xdg.configHome}/zsh";

    # Directory shortcuts
    dirHashes = {
      dl = "$HOME/Downloads";
      docs = "$HOME/Documents";
      dev = "$HOME/Code";
      nix = "$HOME/nixos-config";
      dots = "$HOME/.config";
    };

    # Search paths for cd command (handled by CDPATH in common.nix)
    cdpath = [];  # Using sessionVariables.CDPATH instead

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

    # ZSH-specific shell aliases (inherits from common.nix)
    shellAliases = {
      # ZSH-specific quick edits
      zshrc = "$EDITOR ~/.config/zsh/.zshrc";
      zshenv = "$EDITOR ~/.config/zsh/.zshenv";

      # ZSH-specific reload
      reload = "exec zsh";
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
      # Disable treating # as a special glob character for flake references
      # This allows using .#hostname without quotes
      disable -p '#'
      
      # Configure fzf-tab for better systemctl and other completions
      zstyle ':fzf-tab:*' fzf-command fzf
      zstyle ':fzf-tab:*' fzf-pad 4
      
      # Better formatting for completions with descriptions
      zstyle ':fzf-tab:complete:*:*' fzf-preview 'echo ''${(Q)desc}'
      zstyle ':fzf-tab:complete:*:descriptions' format '[%d]'
      
      # Systemctl specific configuration with enhanced preview
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
            # Inline man page extraction since functions are not available in zstyle context
            local search_opt="''${word#--}"
            search_opt="''${search_opt#-}"
            if man systemctl 2>/dev/null | col -b | grep -A 5 -E "^[[:space:]]*(-[a-z], )?--$search_opt" | head -10; then
              : # Found and displayed
            elif man systemctl 2>/dev/null | col -b | grep -A 3 "^[[:space:]]*$word" | head -5; then
              : # Found and displayed  
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
      
      # Use tmux popup if available, with wider preview for man pages
      zstyle ':fzf-tab:*' fzf-flags '--height=70%' '--layout=reverse' '--info=inline' '--border' '--preview-window=right:60%:wrap'
      
      # Tab width for better column alignment
      zstyle ':fzf-tab:*' fzf-bindings 'tab:down' 'btab:up' 'ctrl-space:toggle' 'ctrl-a:toggle-all'
      zstyle ':fzf-tab:*' continuous-trigger '/'
      
      # Use a tab character for padding to align columns
      zstyle ':fzf-tab:*' prefix ""
      zstyle ':fzf-tab:*' fzf-pad 4
      
      # Better column alignment using printf
      zstyle ':completion:*' list-separator $'\t'
      zstyle ':completion:*:*:*:*:descriptions' format '%F{yellow}-- %d --%f'
      
      # Disable sort for better grouping
      zstyle ':completion:*:*:*:*:*' sort false
      
      # Group results by category
      zstyle ':completion:*' group-name ""
      
      # General command option preview for any command with man pages
      zstyle ':fzf-tab:complete:*:options' fzf-preview '
        # Try to extract the command name from the context
        local cmd="''${words[1]}"
        if [[ -n "$cmd" ]] && man "$cmd" 2>/dev/null | head -1 | grep -q .; then
          # Inline man page extraction 
          local search_opt="''${word#--}"
          search_opt="''${search_opt#-}"
          if man "$cmd" 2>/dev/null | col -b | grep -A 5 -E "^[[:space:]]*(-[a-z], )?--$search_opt" | head -10; then
            : # Found and displayed
          elif man "$cmd" 2>/dev/null | col -b | grep -A 3 "^[[:space:]]*$word" | head -5; then
            : # Found and displayed
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
      
      # Ensure consistent column width for all groups
      zstyle ':fzf-tab:*' show-group full
      zstyle ':fzf-tab:*' switch-group ',' '.'
      
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
