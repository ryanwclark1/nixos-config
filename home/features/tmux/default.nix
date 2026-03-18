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

  programs.tmux = {
    enable = true;
    package = pkgs.tmux;
    plugins = with pkgs; [
      tmuxPlugins.continuum
      tmuxPlugins.yank
      tmuxPlugins.tmux-fzf
    ];

    aggressiveResize = true;
    baseIndex = 1;
    clock24 = true;
    customPaneNavigationAndResize = true;
    disableConfirmationPrompt = false;
    escapeTime = 0;
    focusEvents = true;
    historyLimit = 50000;
    keyMode = "vi";
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

    extraConfig = ''
      set -g detach-on-destroy off
      set -g renumber-windows on
      set -g set-clipboard on
      set -g allow-passthrough on
      # Keep PATH in sync from the client shell to avoid stale fnm shim paths.
      set -g update-environment "DISPLAY KRB5CCNAME MSYSTEM SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY PATH"

      ###################################
      # Configure the forceline plugin

      # Default / desktop settings
      set -g @forceline_theme "catppuccin-frappe"
      set -g @forceline_separator_style "powerline"
      set -g @forceline_window_flags "icon"
      set -g @forceline_window_number_position "left"
      set -g @forceline_status_connect_separator "yes"
      set -g @forceline_status_background "none"

      # Load the forceline plugin after setting options
      source-file ~/.config/tmux/plugins/tmux-forceline/forceline.tmux

      ###################################
      # Status line behavior

      set -g status-position bottom
      set -g status-justify centre
      set -g status-left-length 40
      set -g status-right-length 100

      # Mobile / Termius detection
      # Uses the attached client, not inherited session env
      set -g @is_mobile '#{||:#{m/ri:termius,#{client_termtype}},#{m/ri:termius,#{client_termname}}}'

      # Mobile gets a simple ASCII-safe status line.
      # Narrow desktop also falls back to a simplified layout.
      # Wider desktop gets full forceline rendering.
      set -g status-left '#{?#{E:@is_mobile},#[bold] #S ,#{?#{<:#{client_width},90},#[bold] #S ,#{E:@forceline_status_session}}}'
      set -g status-right '#{?#{E:@is_mobile},#[dim]#{pane_current_command} | %H:%M,#{?#{<:#{client_width},90},%H:%M,#{E:@forceline_status_cpu}#{E:@forceline_status_gpu}#{E:@forceline_status_memory}#{E:@forceline_status_datetime}}}'

      # Reload configuration with Prefix + r
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"
    '';
  };
}
