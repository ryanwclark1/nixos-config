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
  };
}