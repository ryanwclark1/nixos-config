{
  config,
  pkgs,
  ...
}:

{
  home.shellAliases = {
    tm = "tmux";
    tms = "tmux new -s";
    tml = "tmux list-sessions";
    tma = "tmux attach -t";
    tmk = "tmux kill-session -t";
  };

  home.file.".config/tmux/plugins" = {
    source = ./plugins;
    recursive = true;
  };

  programs.tmux = {
    enable = true;
    package = pkgs.tmux;
    plugins = with pkgs.tmuxPlugins; [
      better-mouse-mode
      # battery
      # weather
      # tmux-fzf
      # copycat
      # t-smart-tmux-session-manager
      # sidebar
      # fzf-tmux-url
      # power-theme
      resurrect
      continuum
      # session-wizard
      yank
    ];
    # with pkgs.tmuxPlugins;
    aggressiveResize = true;
    baseIndex = 1;
    clock24 = true;
    customPaneNavigationAndResize = true; # Override the hjkl and HJKL bindings for pane navigation and resizing in VI mode.
    disableConfirmationPrompt = false;
    escapeTime = 0;
    historyLimit = 10000;
    # keyMode = "vi"; # emacs key bindings in tmux command prompt (prefix + :) are better than vi keys, even for vim users
    mouse = true;
    newSession = false;
    prefix = null;
    resizeAmount = 5;
    reverseSplit = false;
    secureSocket = true;
    sensibleOnTop = true;
    shell = "${pkgs.zsh}/bin/zsh";
    shortcut = "b";
    terminal = "tmux-256color";
    extraConfig =
    let
      bg = "default";
      fg = "default";
      bg2 = "brightblack";
      fg2 = "white";
      color = c: "#{@${c}}";

      indicator = let
        accent = color "indicator_color";
        content = "  ";
      in "#[reverse,fg=${accent}]#{?client_prefix,${content},}";

      current_window = let
        accent = color "main_accent";
        index = "#[reverse,fg=${accent},bg=${fg}] #I ";
        name = "#[fg=${bg2},bg=${fg2}] #W ";
        # flags = "#{?window_flags,#{window_flags}, }";
      in "${index}${name}";

      window_status = let
        accent = color "window_color";
        index = "#[reverse,fg=${accent},bg=${fg}] #I ";
        name = "#[fg=${bg2},bg=${fg2}] #W ";
        # flags = "#{?window_flags,#{window_flags}, }";
      in "${index}${name}";

      time = let
        accent = color "main_accent";
        format = "%H:%M";
        icon = pkgs.writeShellScript "icon" ''
          hour=$(date +%H)
          if   [ "$hour" == "00" ] || [ "$hour" == "12" ]; then printf "󱑖"
          elif [ "$hour" == "01" ] || [ "$hour" == "13" ]; then printf "󱑋"
          elif [ "$hour" == "02" ] || [ "$hour" == "14" ]; then printf "󱑌"
          elif [ "$hour" == "03" ] || [ "$hour" == "15" ]; then printf "󱑍"
          elif [ "$hour" == "04" ] || [ "$hour" == "16" ]; then printf "󱑎"
          elif [ "$hour" == "05" ] || [ "$hour" == "17" ]; then printf "󱑏"
          elif [ "$hour" == "06" ] || [ "$hour" == "18" ]; then printf "󱑐"
          elif [ "$hour" == "07" ] || [ "$hour" == "19" ]; then printf "󱑑"
          elif [ "$hour" == "08" ] || [ "$hour" == "20" ]; then printf "󱑒"
          elif [ "$hour" == "09" ] || [ "$hour" == "21" ]; then printf "󱑓"
          elif [ "$hour" == "10" ] || [ "$hour" == "22" ]; then printf "󱑔"
          elif [ "$hour" == "11" ] || [ "$hour" == "23" ]; then printf "󱑕"
          fi
        '';
      in "#[reverse,fg=${accent}] ${format} #(${icon}) ";

      battery = let
        percentage = pkgs.writeShellScript "percentage" (
          if pkgs.stdenv.isDarwin
          then ''
            echo $(pmset -g batt | grep -o "[0-9]\+%" | tr '%' ' ')
          ''
          else ''
            path="/org/freedesktop/UPower/devices/DisplayDevice"
            echo $(${pkgs.upower}/bin/upower -i $path | grep -o "[0-9]\+%" | tr '%' ' ')
          ''
        );
        state = pkgs.writeShellScript "state" (
          if pkgs.stdenv.isDarwin
          then ''
            echo $(pmset -g batt | awk '{print $4}')
          ''
          else ''
            path="/org/freedesktop/UPower/devices/DisplayDevice"
            echo $(${pkgs.upower}/bin/upower -i $path | grep state | awk '{print $2}')
          ''
        );
        icon = pkgs.writeShellScript "icon" ''
          percentage=$(${percentage})
          state=$(${state})
          if [ "$state" == "charging" ] || [ "$state" == "fully-charged" ]; then echo "󰂄"
          elif [ $percentage -ge 75 ]; then echo "󱊣"
          elif [ $percentage -ge 50 ]; then echo "󱊢"
          elif [ $percentage -ge 25 ]; then echo "󱊡"
          elif [ $percentage -ge 0  ]; then echo "󰂎"
          fi
        '';
        color = pkgs.writeShellScript "color" ''
          percentage=$(${percentage})
          state=$(${state})
          if [ "$state" == "charging" ] || [ "$state" == "fully-charged" ]; then echo "green"
          elif [ $percentage -ge 75 ]; then echo "green"
          elif [ $percentage -ge 50 ]; then echo "${fg2}"
          elif [ $percentage -ge 30 ]; then echo "yellow"
          elif [ $percentage -ge 0  ]; then echo "red"
          fi
        '';
      in "#[fg=#(${color})]#(${icon}) #[fg=${fg}]#(${percentage})%";

      pwd = let
        accent = color "main_accent";
        icon = "#[fg=${accent}] ";
        format = "#[fg=${fg}]#{b:pane_current_path}";
      in "${icon}${format}";

      git = let
        icon = pkgs.writeShellScript "branch" ''
          git -C "$1" branch && echo " "
        '';
        branch = pkgs.writeShellScript "branch" ''
          git -C "$1" rev-parse --abbrev-ref HEAD
        '';
      in "#[fg=magenta]#(${icon} #{pane_current_path})#(${branch} #{pane_current_path})";

      separator = "#[fg=${fg}]|";

     sensible_mod = pkgs.writeShellScript "sensible_mod.tmux" ''
        CURRENT_DIR="$( cd "$( dirname "''\${BASH_SOURCE[0]}" )" && pwd )"

        # used to match output from `tmux list-keys`
        KEY_BINDING_REGEX="bind-key[[:space:]]\+\(-r[[:space:]]\+\)\?\(-T prefix[[:space:]]\+\)\?"

        is_osx() {
          local platform=$(uname)
          [ "$platform" == "Darwin" ]
        }

        iterm_terminal() {
          [[ "$TERM_PROGRAM" =~ ^iTerm ]]
        }

        command_exists() {
          local command="$1"
          type "$command" >/dev/null 2>&1
        }

        # returns prefix key, e.g. 'C-a'
        prefix() {
          tmux show-option -gv prefix
        }

        # if prefix is 'C-a', this function returns 'a'
        prefix_without_ctrl() {
          local prefix="$(prefix)"
          echo "$prefix" | cut -d '-' -f2
        }

        option_value_not_changed() {
          local option="$1"
          local default_value="$2"
          local option_value=$(tmux show-option -gv "$option")
          [ "$option_value" == "$default_value" ]
        }

        server_option_value_not_changed() {
          local option="$1"
          local default_value="$2"
          local option_value=$(tmux show-option -sv "$option")
          [ "$option_value" == "$default_value" ]
        }

        key_binding_not_set() {
          local key="$1"
          if $(tmux list-keys | grep -q "''\${KEY_BINDING_REGEX}''\${key}[[:space:]]"); then
            return 1
          else
            return 0
          fi
        }

        key_binding_not_changed() {
          local key="$1"
          local default_value="$2"
          if $(tmux list-keys | grep -q "''\${KEY_BINDING_REGEX}''\${key}[[:space:]]\+''\${default_value}"); then
            # key still has the default binding
            return 0
          else
            return 1
          fi
        }

        main() {
          # OPTIONS

          # enable utf8 (option removed in tmux 2.2)
          tmux set-option -g utf8 on 2>/dev/null

          # enable utf8 in tmux status-left and status-right (option removed in tmux 2.2)
          tmux set-option -g status-utf8 on 2>/dev/null

          # address vim mode switching delay (http://superuser.com/a/252717/65504)
          if server_option_value_not_changed "escape-time" "500"; then
            tmux set-option -s escape-time 0
          fi

          # increase scrollback buffer size
          if option_value_not_changed "history-limit" "2000"; then
            tmux set-option -g history-limit 50000
          fi

          # tmux messages are displayed for 4 seconds
          if option_value_not_changed "display-time" "750"; then
            tmux set-option -g display-time 4000
          fi

          # refresh 'status-left' and 'status-right' more often
          if option_value_not_changed "status-interval" "15"; then
            tmux set-option -g status-interval 5
          fi

          # required (only) on OS X
          if is_osx && command_exists "reattach-to-user-namespace" && option_value_not_changed "default-command" ""; then
            tmux set-option -g default-command "reattach-to-user-namespace -l $SHELL"
          fi

          # upgrade $TERM, tmux 2.0+
          if server_option_value_not_changed "default-terminal" "screen"; then
            tmux set-option -s default-terminal "screen-256color"
          fi

          # emacs key bindings in tmux command prompt (prefix + :) are better than
          # vi keys, even for vim users
          tmux set-option -g status-keys emacs

          # focus events enabled for terminals that support them
          tmux set-option -g focus-events on

          # super useful when using "grouped sessions" and multi-monitor setup
          if ! iterm_terminal; then
            tmux set-window-option -g aggressive-resize on
          fi

          # DEFAULT KEY BINDINGS

          local prefix="$(prefix)"
          local prefix_without_ctrl="$(prefix_without_ctrl)"

          # if C-b is not prefix
          if [ $prefix != "C-b" ]; then
            # unbind obsolete default binding
            if key_binding_not_changed "C-b" "send-prefix"; then
              tmux unbind-key C-b
            fi

            # pressing `prefix + prefix` sends <prefix> to the shell
            if key_binding_not_set "$prefix"; then
              tmux bind-key "$prefix" send-prefix
            fi
          fi

          # If Ctrl-a is prefix then `Ctrl-a + a` switches between alternate windows.
          # Works for any prefix character.
          if key_binding_not_set "$prefix_without_ctrl"; then
            tmux bind-key "$prefix_without_ctrl" last-window
          fi

          # easier switching between next/prev window
          if key_binding_not_set "C-p"; then
            tmux bind-key C-p previous-window
          fi
          if key_binding_not_set "C-n"; then
            tmux bind-key C-n next-window
          fi

          # source `.tmux.conf` file - as suggested in `man tmux`
          if key_binding_not_set "R"; then
            tmux bind-key R run-shell ' \
              tmux source-file ${config.home.homeDirectory}/.config/tmux/.tmux.conf > /dev/null; \
              tmux display-message "Sourced .tmux.conf!"'
          fi
        }
        main
      '';

    in
    ''

      # emacs key bindings in tmux command prompt (prefix + :) are better than
      # vi keys, even for vim users
      set -g mode-keys vi
      # https://yazi-rs.github.io/docs/image-preview
      set -g allow-passthrough all
      set -g renumber-windows on # renumber all windows when any window is closed
      set -g status-interval 1 # update the status bar every 3 seconds

      set -ga update-environment TERM

      ###################################
      # Configure the forceline plugin

      set -g @forceline_flavor "catppuccin_frappe"
      set -g @forceline_window_status "icon"

      set -g @forceline_window_status_style "rounded"
      set -g @forceline_window_number_position "right"

      # set -g @forceline_window_default_fill "number"
      # leave this unset to let applications set the window title
      # set -g @forceline_window_default_text "#W"

      # set -g @forceline_window_current_fill "number"
      # set -g @forceline_window_current_text "#W"

      # set -g @forceline_status_left_separator  " "
      set -g @forceline_status_right_separator ""
      # set -g @forceline_status_fill "icon"
      set -g @forceline_status_connect_separator "no"

      set -g @forceline_directory_text "#{pane_current_path}"
      set -g @forceline_window_current_background "#{@thm_mauve}"

      run ${config.home.homeDirectory}/.config/tmux/plugins/forceline/forceline.tmux

      set -g status-left-length 200    # increase length (from 10)
      set -g status-right-length 200   # increase length (from 10)

      # Make the status line pretty and add some modules
      set -g status-left ""
      set -g  status-right "#{E:@forceline_status_directory}"
      set -ag status-right "#{E:@forceline_status_user}"
      set -ag status-right "#{E:@forceline_status_host}"
      set -ag status-right "#{E:@forceline_status_session}"
      set -agF status-right "#{E:@forceline_status_cpu}"
      set -ag status-right "#{E:@forceline_status_time}"
      set -ag status-right "#{E:@forceline_status_date}"
    '';

      # set -g set-clipboard on      # use system clipboard
      # set -g status-left "${indicator}"
      # set -g status-right "${git} ${pwd} ${separator} ${battery} ${time}"

      # set -g status-style "bg=default"

      # set -g @indicator_color "yellow"
      # set -g @window_color "magenta"
      # set -g @main_accent "blue"
      # set -g pane-active-border fg=black
      # set -g pane-border-style fg=black

      # set -g window-status-current-format "${current_window}"
      # set -g window-status-format "${window_status}"
      # set -g window-status-separator ""

    # extraConfig = ''

      # set -sa terminal-overrides ",xterm*:Tc"
      # bind v copy-mode
      # bind-key -T copy-mode-vi v send-keys -X begin-selection
      # bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      # bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      # bind '"' split-window -v -c "#{pane_current_path}"
      # bind % split-window -h -c "#{pane_current_path}"

    #   # 2x C-a goes back and fourth between most recent windows
    #   bind-key C-a last-window

    #   # auto window rename
    #   set -g automatic-rename
    #   set -g automatic-rename-format '#{pane_current_command}'
    # '';
  };
}