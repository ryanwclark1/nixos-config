{
  config,
  lib,
  pkgs,
  ...
}:
# let
#   tmux-which-key =
#     pkgs.tmuxPlugins.mkTmuxPlugin
#     {
#       pluginName = "tmux-which-key";
#       version = "2025-05-15";
#       src = pkgs.fetchFromGitHub {
#         owner = "alexwforsythe";
#         repo = "tmux-which-key";
#         rev = "1f419775caf136a60aac8e3a269b51ad10b51eb6";
#         sha256 = "sha256-X7FunHrAexDgAlZfN+JOUJvXFZeyVj9yu6WRnxMEA8E=";
#       };
#       rtpFilePath = "plugin.sh.tmux";
#     };

#   tmux-menus =
#     pkgs.tmuxPlugins.mkTmuxPlugin
#     {
#       pluginName = "tmux-menus";
#       version = "v2.2.22";
#       src = pkgs.fetchFromGitHub {
#         owner = "jaclu";
#         repo = "tmux-menus";
#         tag = "v2.2.22";
#         sha256 = "sha256-N2RMatxmpcbziiCfz0B1j6TfOpmZ4Bkx2kTdOs8R2ug=";
#       };
#       rtpFilePath = "plugin.sh.tmux";
#     };
# in

{
  home.shellAliases = {
    tm = "tmux";
    tms = "tmux new -s";
    tml = "tmux list-sessions";
    tma = "tmux attach -t";
    tmk = "tmux kill-session -t";
  };

  home.file.".config/tmux/plugins/tmux-forceline" = {
    force = true;
    source = ./plugins/tmux-forceline;
    recursive = true;
  };

  # home.file = {
  #   ".config/tmux/plugins/tmux-which-key/config.yaml" = {
  #     source = ./plugins/tmux-which-key/config.yaml;
  #     executable = false;
  #   };
  # };

  programs.tmux = {
    enable = true;
    package = pkgs.tmux;
    plugins = with pkgs; [
      tmuxPlugins.continuum
      tmuxPlugins.yank
      # pkgs.tmuxPlugins.tmux-resurrect
      tmuxPlugins.tmux-fzf
    ];
    aggressiveResize = true;
    baseIndex = 1;
    clock24 = true;
    customPaneNavigationAndResize = true; # Override the hjkl and HJKL bindings for pane navigation and resizing in VI mode.
    disableConfirmationPrompt = false;
    escapeTime = 0;
    focusEvents = true;
    historyLimit = 50000;
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
      set -g detach-on-destroy off     # don't exit from tmux when closing a session
      set -g renumber-windows on       # renumber all windows when any window is closed
      set -g set-clipboard on          # use system clipboard

      # https://yazi-rs.github.io/docs/image-preview
      set -g allow-passthrough on
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM

      ###################################
      # Configure the forceline plugin

      # Options must be set BEFORE sourcing the plugin
      set -g @forceline_theme "catppuccin-frappe"
      set -g @forceline_separator_style "powerline"
      set -g @forceline_window_flags "icon"
      set -g @forceline_window_number_position "left"
      set -g @forceline_status_connect_separator "yes"
      set -g @forceline_status_background "none"

      # Load the forceline plugin (theme, modules, status rendering)
      source-file ~/.config/tmux/plugins/tmux-forceline/forceline.tmux

      # Status bar layout using forceline module segments
      set -g status-position bottom
      set -g status-justify centre
      set -g status-left-length 100
      set -g status-right-length 150
      set -g status-left "#{E:@forceline_status_session}"
      set -g status-right "#{E:@forceline_status_cpu}#{E:@forceline_status_gpu}#{E:@forceline_status_memory}#{E:@forceline_status_datetime}"

      # Reload configuration with Prefix + r
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"
    '';
  };
}
