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
    keyMode = "vi"; # emacs key bindings in tmux command prompt (prefix + :) are better than vi keys, even for vim users
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

    in
    ''

      # emacs key bindings in tmux command prompt (prefix + :) are better than
      set -g base-index 1              # start indexing windows at 1 instead of 0
      set -g detach-on-destroy off     # don't exit from tmux when closing a session
      set -g escape-time 0             # zero-out escape time delay
      set -g history-limit 1000000     # increase history size (from 2,000)
      set -g renumber-windows on       # renumber all windows when any window is closed
      set -g set-clipboard on          # use system clipboard

      # https://yazi-rs.github.io/docs/image-preview
      set -g allow-passthrough all
      set -g renumber-windows on # renumber all windows when any window is closed
      set -g status-interval 1 # update the status bar every 3 seconds

      set -ga update-environment TERM

      ###################################
      # Configure the forceline plugin

      set -g @forceline_theme "catppuccin_frappe"
      set -g @forceline_window_status "icon"

      run ${config.home.homeDirectory}/.config/tmux/plugins/tmux-forceline/forceline.tmux
      set -g @forceline_status_left_separator  " "
      set -g @catppuccin_window_middle_separator " █"
      set -g @forceline_status_right_separator ""
      set -g @forceline_status_fill "icon"
      set -g @forceline_status_connect_separator "no"
      set -g @forceline_window_status_style "rounded"
      set -g @forceline_window_number_position "right"
      set -g @forceline_window_default_fill "number"
      set -g @forceline_window_default_text "#W"
      set -g @forceline_window_current_fill "number"
      set -g @forceline_window_current_text "#W#{?window_zoomed_flag,(),}"
      set -g @forceline_directory_text "#{pane_current_path}"
      set -g status-left-length 200    # increase length (from 10)
      set -g status-right-length 200   # increase length (from 10)

      # Make the status line pretty and add some modules
      set -g status-left ""
      set -g  status-right "#{E:@forceline_status_directory}"
      set -ag status-right "#{E:@forceline_status_user}"
      set -ag status-right "#{E:@forceline_status_host}"
      set -ag status-right "#{E:@forceline_status_session}"
      # set -agF status-right "#{E:@forceline_status_cpu}"
      # set -agF status-right "#{E:@forceline_status_weather}"
      # set -agF status-right "#{E:@forceline_status_ipwan}"
      # set -agF status-right "#{E:@forceline_status_test}"
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